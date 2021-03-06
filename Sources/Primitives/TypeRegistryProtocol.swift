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
    case unknownType(DynamicTypeId.Type)
    case typeRegistrationError(type: ScaleDynamicDecodable, as: DType, message: String)
    // Events
    case eventFoundWrongEvent(module: String, event: String, exmodule: String, exevent: String)
    case eventDecodingError(module: String, event: String, error: SDecodingError)
    case eventRegistrationError(event: AnyEvent, message: String)
    // Calls
    case callFoundWrongCall(module: String, function: String, exmodule: String, exfunction: String)
    case callDecodingError(module: String, function: String, error: SDecodingError)
    case callRegistrationError(event: AnyEvent, message: String)
    case callEncodingError(call: AnyCall, error: SEncodingError)
    case callEncodingWrongParametersCount(call: DynamicCall, count: Int, expected: Int)
    case callEncodingUnknownCallType(call: AnyCall)
    // Meta
    case metadata(error: MetadataError)
    // Value Encoding
    case encodingNotSupported(for: DType)
    case encodingValueIsNotCompactCodable(value: ScaleDynamicEncodable)
    case encodingError(error: SEncodingError, value: ScaleDynamicEncodable)
    case encodingExpectedCollection(found: ScaleDynamicEncodable)
    case encodingExpectedMap(found: ScaleDynamicEncodable)
    case encodingExpectedResult(found: ScaleDynamicEncodable)
    case encodingWrongElementCount(in: ScaleDynamicEncodable, expected: Int)
    // Storage
    case storageItemBadPathTypesCount(module: String, field: String, count: Int, expected: Int)
    case storageItemBadItemType(module: String, field: String, type: String, expected: String)
    case storageItemEmptyItem(module: String, field: String)
    case storageItemDecodingError(module: String, field: String, error: SDecodingError)
    case storageItemDecodingBadPrefix(module: String, field: String, prefix: Data, expected: Data)
    // Validation
    case validationError(missingTypes: Dictionary<DType, [String]>)
    // Unknown
    case unknown(error: Error)
}

public protocol TypeRegistryProtocol: AnyObject {
    var ss58AddressFormat: Ss58AddressFormat { get set }
    
    // Storage
    func hash<K: DynamicStorageKey>(of key: K) throws -> Data
    func hash<K: StaticStorageKey>(of key: K) throws -> Data
    func hash<K: DynamicStorageKey>(iteratorOf key: K) throws -> Data
    func hash<K: IterableStaticStorageKey>(iteratorOf key: K) throws -> Data
    func type<K: AnyStorageKey>(valueOf key: K) throws -> DType
    func value<K: DynamicStorageKey>(defaultOf key: K) throws -> DValue
    func value<K: StaticStorageKey>(defaultOf key: K) throws -> K.Value
    func decode<K: DynamicStorageKey>(key: K.Type, module: String, field: String, from data: Data) throws -> K
    func decode<K: StaticStorageKey>(key: K.Type, from data: Data) throws -> K
    
    // Constants
    func type<C: AnyConstant>(of constant: C) throws -> DType
    func value<C: DynamicConstant>(of constant: C) throws -> DValue
    func value<C: Constant>(of constant: C) throws -> C.Value
    
    // Events
    func decode(eventFrom decoder: ScaleDecoder) throws -> AnyEvent
    func decode<E: Event>(event: E.Type, from decoder: ScaleDecoder) throws -> E
    func register<E: Event>(event: E.Type) throws
    
    // Values
    func type<T: DynamicTypeId>(of t: T.Type) throws -> DType
//    func value<T: ScaleDynamicCodable>(dynamic val: T) throws -> DValue
    func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws
    func encode(dynamic: DValue, type: DType, in encoder: ScaleEncoder) throws
    func decode<V: ScaleDynamicDecodable>(static: V.Type, as type: DType, from decoder: ScaleDecoder) throws -> V
    func decode(dynamic: DType, from decoder: ScaleDecoder) throws -> DValue
    func register<T: ScaleDynamicCodable>(type: T.Type, as dynamic: DType) throws
    
    // Calls
    func encode(call: AnyCall, in encoder: ScaleEncoder) throws
    func decode(callFrom decoder: ScaleDecoder) throws -> AnyCall
    func decode<C: Call>(call: C.Type, from decoder: ScaleDecoder) throws -> C
    func register<C: Call>(call: C.Type) throws
}

public typealias ScaleDynamicCodable = ScaleDynamicEncodable & ScaleDynamicDecodable

public protocol DynamicTypeId {
    static var id: String { get }
}

public protocol ScaleDynamicEncodable: DynamicTypeId {
    func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
}

public protocol ScaleDynamicDecodable: DynamicTypeId {
    init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

public protocol ScaleDynamicEncodableCollectionConvertible {
    var encodableCollection: DEncodableCollection { get }
}

public protocol ScaleDynamicEncodableMapConvertible {
    var encodableMap: DEncodableMap { get }
}

public protocol ScaleDynamicEncodableEitherConvertible {
    var encodableEither: DEncodableEither { get }
}

public protocol ScaleDynamicEncodableOptionalConvertible {
    var encodableOptional: DEncodableOptional { get }
}

extension DynamicTypeId {
    public static var id: String { return String(describing: Self.self) }
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
