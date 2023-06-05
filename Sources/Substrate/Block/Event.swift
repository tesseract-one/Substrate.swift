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
    
    init(params: [Value<RuntimeTypeId>]) throws
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
    
    init(paramsFrom decoder: ScaleDecoder, runtime: Runtime) throws {
        guard let type = runtime.resolve(eventType: Self.pallet) else {
            throw EventDecodingError.noEventsInPallet(pallet: Self.pallet)
        }
        let value = try Value(from: decoder, as: type.id, runtime: runtime)
        switch (value.value, type.type.definition) {
        case (.variant(let valvar), .variant(variants: let variants)):
            guard Self.name == valvar.name else {
                throw EventDecodingError.foundWrongEvent(found: (name: valvar.name, pallet: Self.pallet),
                                                         expected: (name: Self.name, pallet: Self.pallet))
            }
            try self.init(params: value, info: variants.first { $0.name == Self.name }!)
        default: throw EventDecodingError.decodedNonVariantValue(value, type.id)
        }
    }
    
    init(params: Value<RuntimeTypeId>, info: RuntimeTypeVariantItem) throws {
        switch params.value {
        case .sequence(let fields):
            try self.init(params: fields)
        case .variant(.sequence(name: let name, values: let fields)):
            guard Self.name == name else {
                throw EventDecodingError.foundWrongEvent(found: (name: name, pallet: Self.pallet),
                                                         expected: (name: Self.name, pallet: Self.pallet))
            }
            try self.init(params: fields)
        case .map(let fields):
            let ordered = try info.fields.map {
                guard let field = fields[$0.name!] else {
                    throw EventDecodingError.fieldNotFound(name: $0.name!)
                }
                return field
            }
            try self.init(params: ordered)
        case .variant(.map(name: let name, fields: let fields)):
            guard Self.name == name else {
                throw EventDecodingError.foundWrongEvent(found: (name: name, pallet: Self.pallet),
                                                         expected: (name: Self.name, pallet: Self.pallet))
            }
            let ordered = try info.fields.map {
                guard let field = fields[$0.name!] else {
                    throw EventDecodingError.fieldNotFound(name: $0.name!)
                }
                return field
            }
            try self.init(params: ordered)
        default: throw EventDecodingError.decodedNonVariantValue(params, params.context)
        }
    }
}

public struct AnyEvent: Event {
    public let pallet: String
    public let name: String
    
    public let params: Value<RuntimeTypeId>
    public let info: RuntimeTypeVariantItem
    
    public init(name: String, pallet: String, params: Value<RuntimeTypeId>, info: RuntimeTypeVariantItem) {
        self.pallet = pallet
        self.name = name
        self.params = params
        self.info = info
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
                      info: variants.first { $0.name == name }!)
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .map(fields), context: value.context),
                      info: variants.first { $0.name == name }!)
        default: throw EventDecodingError.decodedNonVariantValue(value, type.id)
        }
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
