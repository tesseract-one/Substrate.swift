//
//  MetadataV12.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import ScaleCodec
import Primitives

struct ModuleMetadataV12: ScaleDecodable {
    init(from decoder: ScaleDecoder) throws {
    }
}

struct ExtrinsicMetadataV4: ScaleDecodable {
    public let version: UInt8
    public let signedExtensions: [String]
    
    init(from decoder: ScaleDecoder) throws {
        version = try decoder.decode()
        signedExtensions = try decoder.decode()
    }
}


struct MetadataV12: ScaleDecodable {
    public let modules: [ModuleMetadataV12]
    public let extrinsic: ExtrinsicMetadataV4
    
    init(from decoder: ScaleDecoder) throws {
        modules = try decoder.decode()
        extrinsic = try decoder.decode()
    }
}

extension MetadataV12: Primitives.Metadata {
    func prefix<K>(for key: K, with registry: TypeRegistry) throws -> Data where K : AnyStorageKey {
        <#code#>
    }
    
    func key<K>(for key: K, with registry: TypeRegistry) throws -> Data where K : AnyStorageKey {
        <#code#>
    }
    
    func encode<T>(call: T, in encoder: ScaleEncoder, with registry: TypeRegistry) throws where T : AnyCall {
        <#code#>
    }
    
    func decode(call index: Int, module: Int, from decoder: ScaleDecoder, with registry: TypeRegistry) throws -> AnyCall {
        <#code#>
    }
    
    func find(call: Int, module: Int) -> (module: String, function: String)? {
        <#code#>
    }
    
    func decode(event index: Int, module: Int, from decoder: ScaleDecoder, with registry: TypeRegistry) throws -> AnyEvent {
        <#code#>
    }
    
    func find(event: Int, module: Int) -> (module: String, event: String)? {
        <#code#>
    }
    
    func encode(value: ScaleRegistryEncodable, type: SType, in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        <#code#>
    }
    
    func decode(type: SType, from decoder: ScaleDecoder, with registry: TypeRegistry) throws -> ScaleRegistryDecodable {
        <#code#>
    }
}
