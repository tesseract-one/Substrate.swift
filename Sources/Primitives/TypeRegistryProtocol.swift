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
    case typeNotFound(SType)
    case typeDecodingError(type: SType, error: SDecodingError)
    case typeRegistrationError(type: ScaleDynamicDecodable, as: SType, message: String)
    // Events
    case eventNotFound(module: String, event: String)
    case eventDecodingError(module: String, event: String, error: SDecodingError)
    case eventRegistrationError(event: Event, message: String)
}

public protocol TypeRegistryProtocol: class {
    func check(meta: MetadataProtocol) throws
    
    func decodeEvent(event: String, module: String, from decoder: ScaleDecoder, with meta: MetadataProtocol) throws -> AnyEvent
    func registerEvent<E: Event>(_ t: E.Type) throws
    func hasEventType<E: Event>(_ t: E.Type) -> Bool
    
    func encode<V: ScaleDynamicEncodable>(value: V, type: SType, in encoder: ScaleEncoder, with meta: MetadataProtocol) throws
    func decodeValue(type: SType, from decoder: ScaleDecoder, with meta: MetadataProtocol) throws -> ScaleDynamicDecodable
    func registerType<T: ScaleDynamicDecodable>(_ t: T.Type, as type: SType) throws
    func hasValueType<T: ScaleDynamicDecodable>(_ t: T.Type, for type: SType) -> Bool
    
    func encode<C: AnyCall>(call: C, in encoder: ScaleEncoder, with meta: MetadataProtocol) throws
    func decodeCall(event: String, module: String, from decoder: ScaleDecoder, with meta: MetadataProtocol) throws -> AnyCall
    func registerCall<C: Call>(_ t: C.Type) throws
    func hasCallType<C: Call>(_ t: C.Type) -> Bool
}
