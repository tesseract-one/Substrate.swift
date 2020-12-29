//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public protocol Metadata: class {    
    // StorageKey
    func prefix<K: AnyStorageKey>(for key: K, with registry: TypeRegistry) throws -> Data
    func key<K: AnyStorageKey>(for key: K, with registry: TypeRegistry) throws -> Data

    // Call
    func encode<T: AnyCall>(call: T, in encoder: ScaleEncoder, with registry: TypeRegistry) throws
    func decode(call index: Int, module: Int, from decoder: ScaleDecoder, with registry: TypeRegistry) throws -> AnyCall
    func find(call: Int, module: Int) -> (module: String, function: String)?

    // Event
    func decode(event index: Int, module: Int, from decoder: ScaleDecoder, with registry: TypeRegistry) throws -> AnyEvent
    func find(event: Int, module: Int) -> (module: String, event: String)?

    // Generic Values
    func encode(
        value: ScaleRegistryEncodable, type: SType,
        in encoder: ScaleEncoder, with registry: TypeRegistry
    ) throws

    func decode(
        type: SType, from decoder: ScaleDecoder, with registry: TypeRegistry
    ) throws -> ScaleRegistryDecodable
}



