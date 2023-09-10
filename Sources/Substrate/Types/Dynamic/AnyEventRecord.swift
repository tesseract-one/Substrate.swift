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
    public let fields: [String: Value<TypeDefinition>]
    
    private let _runtime: any Runtime
    private let _eventType: TypeDefinition
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public var any: AnyEvent { get throws {
        try _runtime.decode(from: data) { _eventType }
    } }
    
    public func typed<E: PalletEvent>(_ type: E.Type) throws -> E {
        try _runtime.decode(from: data) { _eventType }
    }
    
    public var description: String {
        "{phase: \(phase), event: \(header.pallet).\(header.name), fields: \(fields)}"
    }
}

public extension AnyEventRecord {
    enum Phase: Equatable, Hashable, CustomStringConvertible {
        // Applying an extrinsic.
        case applyExtrinsic(UInt32)
        case other(name: String, fields: [String: Value<TypeDefinition>])
        
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
    public static func validate(info: TypeInfo, as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard let apply = info.first(where: { $0.name == "ApplyExtrinsic" }) else {
            return .failure(.variantNotFound(for: Self.self,
                                             variant: "ApplyExtrinsic", type: type, .get()))
        }
        guard apply.fields.count == 1 else {
            return .failure(.wrongVariantFieldsCount(for: Self.self,
                                                     variant: "ApplyExtrinsic",
                                                     expected: 1, type: type, .get()))
        }
        guard apply.fields[0].type.asPrimitive()?.isUInt != nil else {
            return .failure(.wrongType(for: Self.self,
                                       type: type,
                                       reason: "ApplyExtrinsic.Index is not UInt", .get()))
        }
        return .success(())
    }
}

extension AnyEventRecord.Phase: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: TypeDefinition,
                                       runtime: Runtime) throws
    {
        try Self.validate(as: type, in: runtime).get()
        let value = try Value<TypeDefinition>(from: &decoder, as: type, runtime: runtime)
        let extrinsicId: Value<TypeDefinition>
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
                                      type: type,
                                      reason: "Bad extrinsic id: \(extrinsicId)",
                                      .get())
        }
        self = .applyExtrinsic(u32)
    }
}

extension AnyEventRecord: CompositeValidatableType {
    public static func validate(info: TypeInfo, as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard let phase = info.first(where: { $0.name == "phase" }) else {
            return .failure(.fieldNotFound(for: Self.self, field: "phase",
                                           type: type, .get()))
        }
        let eventNames = ["event", "e", "ev"]
        guard let event = info.first(where: { eventNames.contains($0.name ?? "") }) else {
            return .failure(.fieldNotFound(for: Self.self, field: "event",
                                           type: type, .get()))
        }
        return Phase.validate(as: *phase.type, in: runtime)
            .flatMap { _ in AnyEvent.validate(as: *event.type, in: runtime) }
    }
}

extension AnyEventRecord: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: TypeDefinition,
                                       runtime: Runtime) throws
    {
        let sinfo = try Self.parse(type: type, in: runtime).get()
        try Self.validate(info: sinfo, as: type, in: runtime).get()
        var phase: Phase? = nil
        var event: (name: String, pallet: String, data: Data, type: TypeDefinition)? = nil
        var other: [String: Value<TypeDefinition>] = [:]
        for field in sinfo {
            switch field.name! {
            case "phase": phase = try runtime.decode(from: &decoder, type: *field.type)
            case "event", "e", "ev":
                let info = try AnyEvent.fetchEventData(from: &decoder, runtime: runtime, type: *field.type)
                event = (name: info.name, pallet: info.pallet, data: info.data, type: *field.type)
            default:
                other[field.name!] = try Value(from: &decoder, as: *field.type, runtime: runtime)
            }
        }
        self._runtime = runtime
        self._eventType = event!.type
        self.phase = phase!
        self.header = (name: event!.name, pallet: event!.pallet)
        self.data = event!.data
        self.fields = other
    }
}

// Can be removed after dropping Metadata V14
public extension SomeEventRecord {
    static func eventType(record type: TypeDefinition) -> TypeDefinition? {
        let flat = type.flatten()
        guard case .composite(fields: let fields) = flat.definition else {
            return nil
        }
        let eventNames = ["event", "e", "ev"]
        var type = fields.first { eventNames.contains($0.name ?? "") }?.type
        if type == nil {
            type = flat.parameters?.first { eventNames.contains($0.name.lowercased()) }?.type
        }
        return *type
    }
}
