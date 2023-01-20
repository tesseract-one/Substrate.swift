//
//  Call.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol Call: RegistryScaleEncodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol StaticCall: Call, RegistryScaleDecodable {
    static var pallet: String { get }
    static var name: String { get }
    
    init<R: Registry>(decodingParams decoder: ScaleDecoder, registry: R) throws
    func encodeParams<R: Registry>(in encoder: ScaleEncoder, registry: R) throws
}

public extension StaticCall {
    var pallet: String { Self.pallet }
    var name: String { Self.name }
    
    init(from decoder: ScaleDecoder, registry: Registry) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let callIndex = try decoder.decode(UInt8.self)
        guard let info = registry.resolve(callName: callIndex, pallet: modIndex) else {
            throw CallCodingError.callNotFound(index: callIndex, pallet: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw CallCodingError.foundWrongCall(found: (name: info.name, pallet: info.pallet),
                                                 expected: (name: Self.name, pallet: Self.pallet))
        }
        try self.init(decodingParams: decoder, registry: registry)
    }
    
    func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        guard let info = registry.resolve(callIndex: name, pallet: pallet) else {
            throw CallCodingError.callNotFound(name: name, pallet: pallet)
        }
        try encodeParams(in: encoder.encode(info.pallet).encode(info.index),
                         registry: registry)
    }
}

public struct DynamicCall<C>: Call {
    public let pallet: String
    public let name: String
    
    public let params: Value<C>
    
    public init(name: String, pallet: String, params: Value<C>) {
        self.pallet = pallet
        self.name = name
        self.params = params
    }
    
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        guard let palletIdx = registry.resolve(palletIndex: pallet) else {
            throw CallCodingError.palletNotFound(name: pallet)
        }
        guard let type = registry.resolve(callType: palletIdx) else {
            throw CallCodingError.noCallsInPallet(pallet: pallet)
        }
        try encoder.encode(palletIdx)
        let variant: Value<C>
        switch params.value {
        case .variant(let val):
            guard val.name == self.name else {
                throw CallCodingError.foundWrongCall(found: (name: val.name, pallet: pallet),
                                                     expected: (name: self.name, pallet: pallet))
            }
            variant = params
        case .map(let fields):
            variant = Value(value: .variant(.map(name: name, fields: fields)),
                            context: params.context)
        case .sequence(let vals):
            variant = Value(value: .variant(.sequence(name: name, values: vals)),
                            context: params.context)
        default:
            variant = Value(value: .variant(.sequence(name: name, values: [params])),
                            context: params.context)
        }
        try variant.encode(in: encoder, as: type.id, registry: registry)
    }
}

extension DynamicCall: RegistryScaleDecodable where C == RuntimeTypeId {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        let palletIdx = try decoder.decode(UInt8.self)
        guard let pallet = registry.resolve(palletName: palletIdx) else {
            throw CallCodingError.palletNotFound(index: palletIdx)
        }
        guard let type = registry.resolve(callType: pallet) else {
            throw CallCodingError.noCallsInPallet(pallet: pallet)
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
        default: throw CallCodingError.decodedNonVariantValue(value, type.id)
        }
    }
}

public enum CallCodingError: Error {
    case callNotFound(index: UInt8, pallet: UInt8)
    case callNotFound(name: String, pallet: String)
    case foundWrongCall(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case palletNotFound(name: String)
    case palletNotFound(index: UInt8)
    case noCallsInPallet(pallet: String)
    case decodedNonVariantValue(Value<RuntimeTypeId>, RuntimeTypeId)
}
