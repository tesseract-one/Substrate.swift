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
    public let fields: [String: Value<RuntimeType.Id>]
    
    private let _runtime: any Runtime
    private let _eventTypeId: RuntimeType.Id
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public var any: AnyEvent { get throws {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    } }
    
    public func typed<E: IdentifiableEvent>(_ type: E.Type) throws -> E {
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
        case other(name: String, fields: [String: Value<RuntimeType.Id>])
        
        public var description: String {
            switch self {
            case .applyExtrinsic(let index): return "apply #\(index)"
            case .other(name: let name, fields: let fields):
                return fields.count > 0 ? "\(name)\(fields)" : name
            }
        }
    }
}

extension AnyEventRecord.Phase: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let typeInfo = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        guard case .variant(variants: let variants) = typeInfo.definition else {
            return .failure(.wrongType(got: typeInfo, for: "EventPhase"))
        }
        guard let apply = variants.first(where: { $0.name == "ApplyExtrinsic" }) else {
            return .failure(.variantNotFound(name: "ApplyExtrinsic", in: typeInfo))
        }
        guard apply.fields.count == 1 else {
            return .failure(.wrongValuesCount(in: typeInfo, expected: 1, for: "EventPhase"))
        }
        guard let applyValue = runtime.resolve(type: apply.fields[0].type)?.flatten(runtime) else {
            return .failure(.typeNotFound(apply.fields[0].type))
        }
        guard applyValue.asPrimitive(runtime)?.isUInt != nil else {
            return .failure(.wrongType(got: applyValue, for: "EventPhase.ApplyExtrinsic(Index)"))
        }
        return .success(())
    }
}

extension AnyEventRecord.Phase: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        try Self.validate(runtime: runtime, type: type).getCodableError()
        let value = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
        let extrinsicId: Value<RuntimeType.Id>
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
            throw DynamicCodableError.badDecodedValue(value: extrinsicId.value,
                                                             forType: extrinsicId.context)
        }
        self = .applyExtrinsic(u32)
    }
}

extension AnyEventRecord: RuntimeDynamicValidatable {
    private static func _validate(
        runtime: Runtime, type id: RuntimeType.Id
    ) -> Result<[RuntimeType.Field], DynamicValidationError> {
        guard let typeInfo = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        guard case .composite(fields: let fields) = typeInfo.definition else {
            return .failure(.wrongType(got: typeInfo, for: "EventRecord"))
        }
        guard fields.first?.name != nil else {
            return .failure(.wrongType(got: typeInfo, for: "EventRecord"))
        }
        guard let phase = fields.first(where: { $0.name == "phase" }) else {
            return .failure(.fieldNotFound(name: "phase", in: typeInfo))
        }
        let eventNames = ["event", "e", "ev"]
        guard let event = fields.first(where: { eventNames.contains($0.name ?? "") }) else {
            return .failure(.fieldNotFound(name: "event", in: typeInfo))
        }
        return Phase.validate(runtime: runtime, type: phase.type)
            .flatMap { AnyEvent.validate(runtime: runtime, type: event.type) }
            .map { fields }
    }
    
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        _validate(runtime: runtime, type: id).map{_ in}
    }
}

extension AnyEventRecord: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        let fields = try Self._validate(runtime: runtime, type: type).getCodableError()
        var phase: Phase? = nil
        var event: (name: String, pallet: String, data: Data, type: RuntimeType.Id)? = nil
        var other: [String: Value<RuntimeType.Id>] = [:]
        for field in fields {
            switch field.name! {
            case "phase": phase = try runtime.decode(from: &decoder, id: field.type)
            case "event", "e", "ev":
                let info = try AnyEvent.fetchEventData(from: &decoder, runtime: runtime, type: field.type)
                event = (name: info.name, pallet: info.pallet, data: info.data, type: field.type)
            default:
                other[field.name!] = try Value(from: &decoder, as: field.type, runtime: runtime)
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
    static func eventTypeId(metadata: any Metadata, record id: RuntimeType.Id) -> RuntimeType.Id? {
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
