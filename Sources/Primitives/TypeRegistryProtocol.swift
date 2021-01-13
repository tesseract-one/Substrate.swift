//
//  TypeRegistryProtocol.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public enum TypeRegistryError: Error {
    // Types
    case typeNotFound(DType)
    case typeDecodingError(type: DType, error: SDecodingError)
    case typeRegistrationError(type: ScaleDynamicDecodable, as: DType, message: String)
    // Events
    case eventNotFound(module: String, event: String)
    case eventDecodingError(module: String, event: String, error: SDecodingError)
    case eventRegistrationError(event: AnyEvent, message: String)
    // Meta
    case metadata(error: MetadataError)
    // Value Encoding
    case encodingNotSupported(for: DType)
    case encodingValueIsNotCompactCodable(value: ScaleDynamicEncodable)
    case encodingError(error: SEncodingError, value: ScaleDynamicEncodable)
    case encodingExpectedCollection(found: ScaleDynamicEncodable)
    case encodingExpectedMap(found: ScaleDynamicEncodable)
    case encodingWrongElementCount(in: ScaleDynamicEncodable, expected: Int)
    // Unknown
    case unknown(error: Error)
}

public protocol TypeRegistryProtocol: class {
    // Storage
    func key(for key: AnyStorageKey) throws -> Data
    func prefix(for key: AnyStorageKey) throws -> Data
    func defaultValue(for key: AnyStorageKey) throws -> DValue
    func defaultValue<K: StorageKey>(parsed key: K) throws -> K.Value
    
    // Constants
    func value(of constant: AnyConstant) throws -> DValue
    func value<C: Constant>(parsed constant: C) throws -> C.Value
    
    // Events
    func decodeEvent(from decoder: ScaleDecoder) throws -> AnyEvent
    func decode<E: Event>(event: E.Type, from decoder: ScaleDecoder) throws -> E
    func register<E: Event>(event: E.Type) throws
    
    // Values
    func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws
    func decode<V: ScaleDynamicDecodable>(static: V.Type, as type: DType, from decoder: ScaleDecoder) throws -> V
    func decode(dynamic: DType, from decoder: ScaleDecoder) throws -> DValue
    func register<T: ScaleDynamicDecodable>(type: T.Type, as dynamic: DType) throws
    
    // Calls
    func encode(call: AnyCall, in encoder: ScaleEncoder) throws
    func decodeCall(from decoder: ScaleDecoder) throws -> AnyCall
    func decode<C: Call>(call: C.Type, from decoder: ScaleDecoder) throws -> C
    func register<C: Call>(call: C.Type) throws
}

public typealias ScaleDynamicCodable = ScaleDynamicEncodable & ScaleDynamicDecodable

public protocol ScaleDynamicEncodable {
    func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
}

public protocol ScaleDynamicDecodable {
    init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

extension ScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder)
    }
}

extension ScaleDecodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(from: decoder)
    }
}
