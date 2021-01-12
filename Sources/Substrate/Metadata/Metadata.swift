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
    public let modulesByName: Dictionary<String, MetadataModuleInfo>
    public let modulesByIndex: Dictionary<UInt8, MetadataModuleInfo>
    public let signedExtensions: [String]
    
    public init(runtime: RuntimeMetadata) throws {
        let modules = try runtime.modules.map { try ($0.name, $0.index, MetadataModuleInfo(runtime: $0)) }
        let modulesByName = modules.map { ($0, $2) }
        let modulesByIndex = modules.map { ($1, $2) }
        self.modulesByName = Dictionary(uniqueKeysWithValues: modulesByName)
        self.modulesByIndex = Dictionary(uniqueKeysWithValues: modulesByIndex)
        signedExtensions = runtime.extrinsic.signedExtensions
    }
}

// StorageKey
extension Metadata {
    public func prefix<K: AnyStorageKey>(for key: K) throws -> Data {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return storage.prefixHash()
    }

    public func key<K: AnyStorageKey>(for key: K, registry: TypeRegistryProtocol) throws -> Data {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return try storage.key(path: key.path, registry: registry)
    }
}
