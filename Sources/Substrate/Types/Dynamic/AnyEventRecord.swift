//
//  AnyEventRecord.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation
import ScaleCodec

public enum AnyEventPhase: Equatable, Hashable, CustomStringConvertible {
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

public struct AnyEventRecord: SomeEventRecord, CustomStringConvertible {
    public let phase: AnyEventPhase
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

extension AnyEventPhase: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        guard let typeInfo = runtime.resolve(type: type)?.flatten(runtime) else {
            throw RuntimeDynamicCodableError.typeNotFound(type)
        }
        guard case .variant(variants: let variants) = typeInfo.definition else {
            throw RuntimeDynamicCodableError.wrongType(got: typeInfo, for: "EventPhase")
        }
        guard variants.firstIndex(where: { $0.name == "ApplyExtrinsic" }) != nil else {
            throw RuntimeDynamicCodableError.variantNotFound(name: "ApplyExtrinsic", in: typeInfo)
        }
        let value = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
        let extrinsicId: Value<RuntimeType.Id>
        switch value.value {
        case .variant(.sequence(name: let name, values: let vals)):
            guard name == "ApplyExtrinsic" else {
                let fields = Dictionary(uniqueKeysWithValues: vals.enumerated().map { (String($0), $1) })
                self = .other(name: name, fields: fields)
                return
            }
            guard vals.count == 1 else {
                throw RuntimeDynamicCodableError.wrongValuesCount(in: typeInfo, expected: 1, for: "EventPhase")
            }
            extrinsicId = vals[0]
        case .variant(.map(name: let name, fields: let fields)):
            guard name == "ApplyExtrinsic" else {
                self = .other(name: name, fields: fields)
                return
            }
            guard fields.count == 1 else {
                throw RuntimeDynamicCodableError.wrongValuesCount(in: typeInfo, expected: 1, for: "EventPhase")
            }
            extrinsicId = fields.first!.value
        default:
            throw RuntimeDynamicCodableError.wrongType(got: typeInfo, for: "EventPhase")
        }
        guard let uint = extrinsicId.uint, let u32 = UInt32(exactly: uint) else {
            throw RuntimeDynamicCodableError.badDecodedValue(value: extrinsicId.value,
                                                             forType: extrinsicId.context)
        }
        self = .applyExtrinsic(u32)
    }
}

extension AnyEventRecord: RuntimeDynamicDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        guard let typeInfo = runtime.resolve(type: type)?.flatten(runtime) else {
            throw RuntimeDynamicCodableError.typeNotFound(type)
        }
        guard case .composite(fields: let fields) = typeInfo.definition else {
            throw RuntimeDynamicCodableError.wrongType(got: typeInfo, for: "EventRecord")
        }
        guard fields.first?.name != nil else {
            throw RuntimeDynamicCodableError.wrongType(got: typeInfo, for: "EventRecord")
        }
        var phase: AnyEventPhase? = nil
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
        guard let event = event, let phase = phase else {
            throw RuntimeDynamicCodableError.wrongType(got: typeInfo, for: "EventRecord")
        }
        self._runtime = runtime
        self._eventTypeId = event.type
        self.phase = phase
        self.header = (name: event.name, pallet: event.pallet)
        self.data = event.data
        self.fields = other
    }
}
