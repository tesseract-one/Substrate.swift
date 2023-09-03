//
//  AnyEventRecord.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation
import ScaleCodec

public struct AnyEventRecord: SomeEventRecord, CustomStringConvertible {
    public let phase: Phase
    public let header: (name: String, pallet: String)
    public let data: Data
    public let fields: [String: Value<NetworkType.Id>]
    
    private let _runtime: any Runtime
    private let _eventTypeId: NetworkType.Id
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public var any: AnyEvent { get throws {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    } }
    
    public func typed<E: PalletEvent>(_ type: E.Type) throws -> E {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    }
    
    public var description: String {
        "{phase: \(phase), event: \(header.pallet).\(header.name), fields: \(fields)}"
    }
}

public extension AnyEventRecord {
    enum Phase: Equatable, Hashable, CustomStringConvertible {
        // Applying an extrinsic.
        case applyExtrinsic(UInt32)
        case other(name: String, fields: [String: Value<NetworkType.Id>])
        
        public var description: String {
            switch self {
            case .applyExtrinsic(let index): return "apply #\(index)"
            case .other(name: let name, fields: let fields):
                return fields.count > 0 ? "\(name)\(fields)" : name
            }
        }
    }
}

extension AnyEventRecord.Phase: VariantValidatableType {
    public static func validate(info: TypeInfo, type: NetworkType.Info,
                                runtime: Runtime) -> Result<Void, TypeError>
    {
        guard let apply = info.first(where: { $0.name == "ApplyExtrinsic" }) else {
            return .failure(.variantNotFound(for: Self.self,
                                             variant: "ApplyExtrinsic", in: type.type))
        }
        guard apply.fields.count == 1 else {
            return .failure(.wrongVariantFieldsCount(for: Self.self,
                                                     variant: "ApplyExtrinsic",
                                                     expected: 1, in: type.type))
        }
        guard apply.fields[0].type.type.asPrimitive(runtime)?.isUInt != nil else {
            return .failure(.wrongType(for: Self.self,
                                       got: type.type, reason: "ApplyExtrinsic.Index is not UInt"))
        }
        return .success(())
    }
}

extension AnyEventRecord.Phase: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: NetworkType.Id,
                                       runtime: Runtime) throws
    {
        let info = try Self.validate(runtime: runtime, type: type).get()
        let value = try Value<NetworkType.Id>(from: &decoder, as: type, runtime: runtime)
        let extrinsicId: Value<NetworkType.Id>
        switch value.value {
        case .variant(.sequence(name: let name, values: let vals)):
            guard name == "ApplyExtrinsic" else {
                let fields = Dictionary(uniqueKeysWithValues: vals.enumerated().map { (String($0), $1) })
                self = .other(name: name, fields: fields)
                return
            }
            extrinsicId = vals[0] // it's safe. We validated before
        case .variant(.map(name: let name, fields: let fields)):
            guard name == "ApplyExtrinsic" else {
                self = .other(name: name, fields: fields)
                return
            }
            extrinsicId = fields.first!.value // it's safe. We validated before
        default: fatalError("Should never happen! We checked that it is a variant")
        }
        guard let uint = extrinsicId.uint, let u32 = UInt32(exactly: uint) else {
            throw TypeError.wrongType(for: Self.self,
                                      got: info.type,
                                      reason: "Bad extrinsic id: \(extrinsicId)")
        }
        self = .applyExtrinsic(u32)
    }
}

extension AnyEventRecord: CompositeValidatableType {
    public static func validate(info: TypeInfo, type: NetworkType.Info,
                                runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard let phase = info.first(where: { $0.name == "phase" }) else {
            return .failure(.fieldNotFound(for: Self.self, field: "phase", in: type.type))
        }
        let eventNames = ["event", "e", "ev"]
        guard let event = info.first(where: { eventNames.contains($0.name ?? "") }) else {
            return .failure(.fieldNotFound(for: Self.self, field: "event", in: type.type))
        }
        return Phase.validate(runtime: runtime, type: phase.type)
            .flatMap { _ in AnyEvent.validate(runtime: runtime, type: event.type) }
    }
}

extension AnyEventRecord: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: NetworkType.Id,
                                       runtime: Runtime) throws
    {
        guard let tinfo = runtime.resolve(type: type) else {
            throw TypeError.typeNotFound(for: Self.self, id: type)
        }
        let info = try Self.typeInfo(runtime: runtime, type: type.i(tinfo)).get()
        try Self.validate(info: info, type: type.i(tinfo), runtime: runtime).get()
        var phase: Phase? = nil
        var event: (name: String, pallet: String, data: Data, type: NetworkType.Id)? = nil
        var other: [String: Value<NetworkType.Id>] = [:]
        for field in info {
            switch field.name! {
            case "phase": phase = try runtime.decode(from: &decoder, id: field.type.id)
            case "event", "e", "ev":
                let info = try AnyEvent.fetchEventData(from: &decoder, runtime: runtime, type: field.type.id)
                event = (name: info.name, pallet: info.pallet, data: info.data, type: field.type.id)
            default:
                other[field.name!] = try Value(from: &decoder, as: field.type.id, runtime: runtime)
            }
        }
        self._runtime = runtime
        self._eventTypeId = event!.type
        self.phase = phase!
        self.header = (name: event!.name, pallet: event!.pallet)
        self.data = event!.data
        self.fields = other
    }
}

// Can be removed after dropping Metadata V14
public extension SomeEventRecord {
    static func eventTypeId(metadata: any Metadata, record id: NetworkType.Id) -> NetworkType.Id? {
        guard let typeInfo = metadata.resolve(type: id)?.flatten(metadata) else {
            return nil
        }
        guard case .composite(fields: let fields) = typeInfo.definition else {
            return nil
        }
        let eventNames = ["event", "e", "ev"]
        var type = fields.first { eventNames.contains($0.name ?? "") }?.type
        if type == nil {
            type = typeInfo.parameters.first { eventNames.contains($0.name.lowercased()) }?.type
        }
        return type
    }
}
