//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public class Metadata {
    public let registry: TypeRegistryProtocol
    
    public let modulesByName: Dictionary<String, MetadataModuleInfo>
    public let modulesByIndex: Dictionary<UInt8, MetadataModuleInfo>
    public let signedExtensions: [Any]
    
    public init(runtime: RuntimeMetadata, registry: TypeRegistryProtocol) throws {
        self.registry = registry
        let modules = try runtime.modules.map { try ($0.name, $0.index, MetadataModuleInfo(runtime: $0)) }
        let modulesByName = modules.map { ($0, $2) }
        let modulesByIndex = modules.map { ($1, $2) }
        self.modulesByName = Dictionary(uniqueKeysWithValues: modulesByName)
        self.modulesByIndex = Dictionary(uniqueKeysWithValues: modulesByIndex)
        signedExtensions = runtime.extrinsic.signedExtensions
    }
}

extension Metadata: MetadataProtocol {
    public func decode(callFrom decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    
    public func decode(eventFrom decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    // StorageKey
    public func prefix<K: AnyStorageKey>(for key: K) throws -> Data {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return storage.prefixHash()
    }
    
    public func key<K: AnyStorageKey>(for key: K) throws -> Data {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return try storage.key(path: key.path, meta: self)
    }

    // Call
    public func encode<T: AnyCall>(call: T, in encoder: ScaleEncoder) throws {
        fatalError("Not implemented")
    }
    public func decode(call index: Int, module: Int, from decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    public func find(call: Int, module: Int) -> (module: String, function: String)? {
        fatalError("Not implemented")
    }

    // Event
    public func decode(event index: Int, module: Int, from decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    public func find(event: Int, module: Int) -> (module: String, event: String)? {
        fatalError("Not implemented")
    }

    // Generic Values
    public func encode(
        value: ScaleDynamicEncodable, type: SType,
        in encoder: ScaleEncoder
    ) throws {
        do {
            try registry.encode(value: value, type: type, in: encoder, with: self)
        } catch TypeRegistryError.typeNotFound(_) {
            switch type {
            case .null: return
            case .optional(element: let t):
                
            default:
                <#code#>
            }
        }
    }

    public func decode(
        type: SType, from decoder: ScaleDecoder
    ) throws -> ScaleDynamicDecodable {
        fatalError("Not implemented")
    }
}
