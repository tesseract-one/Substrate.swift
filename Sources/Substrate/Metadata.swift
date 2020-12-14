//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import Primitives
import ScaleCodec
import RPC


public struct VersionedMetadata: ScaleDecodable {
    public let magicNumber: UInt32
    public let metadata: Metadata
    
    public init(from decoder: ScaleDecoder) throws {
        magicNumber = try decoder.decode()
        let version = try decoder.decode(UInt8.self)
        switch version {
        case 12:
            metadata = try decoder.decode(MetadataV12.self)
        default: throw SDecodingError.dataCorrupted(
            SDecodingError.Context(
                path: decoder.path,
                description: "Unsupported metadata version \(version)"))
        }
    }
}


struct MetadataV12: ScaleDecodable, Metadata {
    init(from decoder: ScaleDecoder) throws {
        <#code#>
    }
    
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
