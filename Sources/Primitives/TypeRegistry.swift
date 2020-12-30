//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public enum TypeRegistryError: Error {
    // Types
    case typeNotFound(SType)
    case typeDecodingError(type: SType, error: SDecodingError)
    case typeRegistrationError(type: ScaleRegistryDecodable, as: SType, message: String)
    // Events
    case eventNotFound(module: String, event: String)
    case eventDecodingError(module: String, event: String, error: SDecodingError)
    case eventRegistrationError(event: Event, message: String)
    // Metadata
    case metadataError(metadata: Metadata, message: String)
}

public protocol TypeRegistry: class {
    var metadata: Metadata! { get set }
    
    func initialize() throws
    
    func decodeEvent(from decoder: ScaleDecoder) throws -> AnyEvent
    func registerEvent<E: Event>(_ t: E.Type) throws
    func hasEventType<E: Event>(_ t: E.Type) throws
    
    func encode<V: ScaleRegistryEncodable>(value: V, type: SType, in encoder: ScaleEncoder) throws
    func decodeValue(type: SType, from decoder: ScaleDecoder) throws -> ScaleRegistryDecodable
    func registerType<T: ScaleRegistryDecodable>(_ t: T.Type, as type: SType) throws
    func hasValueType<T: ScaleRegistryDecodable>(_ t: T.Type, for type: SType) throws
    
    func encode<C: AnyCall>(call: C, in encoder: ScaleEncoder) throws
    func decodeCall(from decoder: ScaleDecoder) throws -> AnyCall
    func registerCall<C: Call>(_ t: C.Type) throws
    func hasCallType<C: ScaleRegistryDecodable>(_ t: C.Type) throws
}

public typealias ScaleRegistryCodable = ScaleRegistryEncodable & ScaleRegistryDecodable

public protocol ScaleRegistryEncodable {
    func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws
}

public protocol ScaleRegistryDecodable {
    init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws
}

extension ScaleEncodable {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder)
    }
}

extension ScaleDecodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        try self.init(from: decoder)
    }
}
