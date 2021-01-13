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
    private func _getStorageInfo(for key: AnyStorageKey) throws -> MetadataStorageItemInfo {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return storage
    }
    
    public func prefix(for key: AnyStorageKey) throws -> Data {
        return try _getStorageInfo(for: key).prefixHash()
    }

    public func key(for key: AnyStorageKey, registry: TypeRegistryProtocol) throws -> Data {
        return try _getStorageInfo(for: key).key(path: key.path, registry: registry)
    }
    
    public func defaultValue(for key: AnyStorageKey, registry: TypeRegistryProtocol) throws -> DValue {
        return try _getStorageInfo(for: key).getDefault(registry: registry)
    }
    
    public func defaultValue<K: StorageKey>(parsed key: K, registry: TypeRegistryProtocol) throws -> K.Value {
        return try _getStorageInfo(for: key).parseDefault(K.Value.self, registry: registry)
    }
    
    public func valueType(for key: AnyStorageKey) throws -> DType {
        return try _getStorageInfo(for: key).valueType
    }
}

// Constants
extension Metadata {
    private func _getConstantInfo(for constant: AnyConstant) throws -> MetadataConstantInfo {
        guard let module = modulesByName[constant.module] else {
            throw MetadataError.moduleNotFound(name: constant.module)
        }
        guard let info = module.constants[constant.name] else {
            throw MetadataError.constantNotFound(module: constant.module, name: constant.name)
        }
        return info
    }
    
    public func value(of constant: AnyConstant, registry: TypeRegistryProtocol) throws -> DValue {
        return try _getConstantInfo(for: constant).get(registry: registry)
    }
    
    public func value<C: Constant>(parsed constant: C, registry: TypeRegistryProtocol) throws -> C.Value {
        return try _getConstantInfo(for: constant).parsed(C.Value.self, registry: registry)
    }
    
    public func valueType(of constant: AnyConstant) throws -> DType {
        return try _getConstantInfo(for: constant).type
    }
}
