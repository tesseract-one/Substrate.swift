//
//  Event.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec

public protocol Event: ScaleRuntimeDecodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol StaticEvent: Event {
    static var pallet: String { get }
    static var name: String { get }
    
    init(paramsFrom decoder: ScaleDecoder, runtime: Runtime) throws
}

public extension StaticEvent {
    var pallet: String { Self.pallet }
    var name: String { Self.name }
    
    init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let evIndex = try decoder.decode(UInt8.self)
        guard let info = runtime.resolve(eventName: evIndex, pallet: modIndex) else {
            throw EventDecodingError.eventNotFound(index: evIndex, pallet: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw EventDecodingError.foundWrongEvent(found: (name: info.name, pallet: info.pallet),
                                                     expected: (name: Self.name, pallet: Self.pallet))
        }
        try self.init(paramsFrom: decoder, runtime: runtime)
    }
}

public struct AnyEvent: Event, CustomStringConvertible {
    public let pallet: String
    public let name: String
    
    public let params: Value<RuntimeTypeId>
    public let info: RuntimeTypeVariantItem
    public let runtime: any Runtime
    
    public init(name: String, pallet: String, params: Value<RuntimeTypeId>,
                info: RuntimeTypeVariantItem, runtime: any Runtime)
    {
        self.pallet = pallet
        self.name = name
        self.params = params
        self.info = info
        self.runtime = runtime
    }
    
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        let palletIdx = try decoder.decode(UInt8.self)
        guard let pallet = runtime.resolve(palletName: palletIdx) else {
            throw EventDecodingError.palletNotFound(index: palletIdx)
        }
        guard let type = runtime.resolve(eventType: pallet) else {
            throw EventDecodingError.noEventsInPallet(pallet: pallet)
        }
        let value = try Value(from: decoder, as: type.id, runtime: runtime)
        guard case .variant(let variants) = type.type.definition else {
            throw EventDecodingError.decodedNonVariantValue(value, type.id)
        }
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .sequence(values), context: value.context),
                      info: variants.first { $0.name == name }!,
                      runtime: runtime)
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .map(fields), context: value.context),
                      info: variants.first { $0.name == name }!,
                      runtime: runtime)
        default: throw EventDecodingError.decodedNonVariantValue(value, type.id)
        }
    }
    
    public func typed<E: StaticEvent>(_ type: E.Type) throws -> E {
        guard E.pallet == pallet && E.name == name else {
            throw EventDecodingError.foundWrongEvent(found: (E.name, E.pallet),
                                                     expected: (name, pallet))
        }
        let pIndex = runtime.resolve(palletIndex: pallet)!
        let encoder = runtime.encoder()
        let value: Value<RuntimeTypeId>
        try encoder.encode(pIndex)
        switch params.value {
        case .map(let fields):
            value = .variant(name: name, fields: fields, params.context)
        case .sequence(let vals):
            value = .variant(name: name, values: vals, params.context)
        default:
            value = params
        }
        try value.encode(in: encoder, runtime: runtime)
        return try E(from: runtime.decoder(with: encoder.output), runtime: runtime)
    }
    
    public var description: String {
        "\(pallet).\(name)(\(params))"
    }
}

public enum EventDecodingError: Error {
    case eventNotFound(index: UInt8, pallet: UInt8)
    case palletNotFound(index: UInt8)
    case noEventsInPallet(pallet: String)
    case foundWrongEvent(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case fieldNotFound(name: String)
    case wrongValueType(value: Value<RuntimeTypeId>, expected: Value<Void>.Def)
    case decodedNonVariantValue(Value<RuntimeTypeId>, RuntimeTypeId)
}
