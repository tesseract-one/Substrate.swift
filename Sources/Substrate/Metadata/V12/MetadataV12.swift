//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

struct MetadataV12: ScaleDecodable {
    public let modules: [ModuleMetadata]
    public let extrinsic: ExtrinsicMetadata
    
    init(from decoder: ScaleDecoder) throws {
        modules = try decoder.decode()
        extrinsic = try decoder.decode()
    }
}

extension MetadataV12: SubstratePrimitives.Metadata {
    // StorageKey
    func prefix<K: AnyStorageKey>(for key: K, with registry: SubstratePrimitives.TypeRegistry) throws -> Data {
        fatalError("Not implemented")
    }
    func key<K: AnyStorageKey>(for key: K, with registry: SubstratePrimitives.TypeRegistry) throws -> Data {
        fatalError("Not implemented")
    }
    
    // Call
    func encode<T: AnyCall>(call: T, in encoder: ScaleEncoder, with registry: SubstratePrimitives.TypeRegistry) throws {
        fatalError("Not implemented")
    }
    func decode(call index: Int, module: Int, from decoder: ScaleDecoder, with registry: SubstratePrimitives.TypeRegistry) throws -> AnyCall {
        fatalError("Not implemented")
    }
    func find(call: Int, module: Int) -> (module: String, function: String)? {
        fatalError("Not implemented")
    }
    
    // Event
    func decode(event index: Int, module: Int, from decoder: ScaleDecoder, with registry: SubstratePrimitives.TypeRegistry) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    func find(event: Int, module: Int) -> (module: String, event: String)? {
        fatalError("Not implemented")
    }
    
    // Generic Values
    func encode(
        value: ScaleRegistryEncodable, type: SType,
        in encoder: ScaleEncoder, with registry: SubstratePrimitives.TypeRegistry
    ) throws {
        fatalError("Not implemented")
    }
    
    func decode(
        type: SType, from decoder: ScaleDecoder, with registry: SubstratePrimitives.TypeRegistry
    ) throws -> ScaleRegistryDecodable {
        fatalError("Not implemented")
    }
}
