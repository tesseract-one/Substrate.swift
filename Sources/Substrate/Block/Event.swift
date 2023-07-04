//
//  Event.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec

public protocol Event: RuntimeDecodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol StaticEvent: Event {
    static var pallet: String { get }
    static var name: String { get }
    
    init<D: ScaleCodec.Decoder>(paramsFrom decoder: inout D, runtime: Runtime) throws
}

public extension StaticEvent {
    var pallet: String { Self.pallet }
    var name: String { Self.name }
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let evIndex = try decoder.decode(UInt8.self)
        guard let info = runtime.resolve(eventName: evIndex, pallet: modIndex) else {
            throw EventDecodingError.eventNotFound(index: evIndex, pallet: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw EventDecodingError.foundWrongEvent(found: (name: info.name, pallet: info.pallet),
                                                     expected: (name: Self.name, pallet: Self.pallet))
        }
        try self.init(paramsFrom: &decoder, runtime: runtime)
    }
}

public struct AnyEvent: Event, CustomStringConvertible {
    public let pallet: String
    public let name: String
    
    public let params: Value<RuntimeTypeId>
    
    public init(name: String, pallet: String, params: Value<RuntimeTypeId>) {
        self.pallet = pallet
        self.name = name
        self.params = params
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        var value = try Value(from: &decoder, as: runtime.types.event.id, runtime: runtime)
        let pallet: String
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            guard values.count == 1 else {
                throw EventDecodingError.tooManyFieldsInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw EventDecodingError.tooManyFieldsInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = fields.values.first!
        default: throw EventDecodingError.decodedNonVariantValue(value)
        }
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .sequence(values), context: value.context))
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .map(fields), context: value.context))
        default: throw EventDecodingError.decodedNonVariantValue(value)
        }
    }
    
    public static func fetchEventData<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> (name: String, pallet: String, data: Data) {
        let size = try Value<Void>.calculateSize(in: decoder, for: runtime.types.event.id, runtime: runtime)
        let hBytes = try decoder.peek(count: 2)
        guard let header = runtime.resolve(eventName: hBytes[1], pallet: hBytes[0]) else {
            throw EventDecodingError.eventNotFound(index: hBytes[1], pallet: hBytes[0])
        }
        return try (name: header.name, pallet: header.pallet, data: decoder.read(count: size))
    }
    
    public var description: String {
        "\(pallet).\(name)(\(params))"
    }
}

public enum EventDecodingError: Error {
    case eventNotFound(index: UInt8, pallet: UInt8)
    case foundWrongEvent(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case decodedNonVariantValue(Value<RuntimeTypeId>)
    case tooManyFieldsInVariant(variant: Value<RuntimeTypeId>, expected: Int)
}
