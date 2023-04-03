//
//  Event.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec

public protocol Event: RegistryScaleDecodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol StaticEvent: Event {
    static var pallet: String { get }
    static var name: String { get }
    
    init(decodingBody decoder: ScaleDecoder, registry: Registry) throws
}

public extension StaticEvent {
    var pallet: String { Self.pallet }
    var name: String { Self.name }
    
    init(from decoder: ScaleDecoder, registry: Registry) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let evIndex = try decoder.decode(UInt8.self)
        guard let info = registry.resolve(eventName: evIndex, pallet: modIndex) else {
            throw EventDecodingError.eventNotFound(index: evIndex, pallet: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw EventDecodingError.foundWrongEvent(found: (name: info.name, pallet: info.pallet),
                                                     expected: (name: Self.name, pallet: Self.pallet))
        }
        try self.init(decodingBody: decoder, registry: registry)
    }
}

public struct DynamicEvent: Event {
    public let pallet: String
    public let name: String
    
    public let params: Value<RuntimeTypeId>
    
    public init(name: String, pallet: String, params: Value<RuntimeTypeId>) {
        self.pallet = pallet
        self.name = name
        self.params = params
    }
    
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        let palletIdx = try decoder.decode(UInt8.self)
        guard let pallet = registry.resolve(palletName: palletIdx) else {
            throw EventDecodingError.palletNotFound(index: palletIdx)
        }
        guard let type = registry.resolve(eventType: pallet) else {
            throw EventDecodingError.noEventsInPallet(pallet: pallet)
        }
        let value = try Value(from: decoder, as: type.id, registry: registry)
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .sequence(values), context: value.context))
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .map(fields), context: value.context))
        default: throw EventDecodingError.decodedNonVariantValue(value, type.id)
        }
    }
}

public enum EventDecodingError: Error {
    case eventNotFound(index: UInt8, pallet: UInt8)
    case palletNotFound(index: UInt8)
    case noEventsInPallet(pallet: String)
    case foundWrongEvent(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case decodedNonVariantValue(Value<RuntimeTypeId>, RuntimeTypeId)
}
