//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public protocol TypeRegistry {
    var metadata: Metadata { get }
    
    init(metadata: Metadata) throws
    
    func decodeEvent(module: String, event: String, from decoder: ScaleDecoder) throws -> Event
    func registerEvent<E: Event>(_ t: E.Type) throws
    
    func decodeValue(type: SType, from decoder: ScaleDecoder) throws -> ScaleRegistryDecodable
    func registerType<T: ScaleRegistryDecodable>(_ t: T.Type, as type: SType) throws
}

typealias ScaleRegistryCodable = ScaleRegistryEncodable & ScaleRegistryDecodable

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
