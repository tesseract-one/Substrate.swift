//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
#if !COCOAPODS
import SubstratePrimitives
#endif

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

// Modules
extension Metadata {
    public func module(index: UInt8) throws -> MetadataModuleInfo {
        guard let module = modulesByIndex[index] else {
            throw MetadataError.moduleNotFound(index: index)
        }
        return module
    }
    
    public func module(name: String) throws -> MetadataModuleInfo {
        guard let module = modulesByName[name] else {
            throw MetadataError.moduleNotFound(name: name)
        }
        return module
    }
}

// StorageKey
extension Metadata {
    private func _getStorageInfo(for field: String, in module: String) throws -> MetadataStorageItemInfo {
        guard let mod = modulesByName[module] else {
            throw MetadataError.moduleNotFound(name: module)
        }
        guard let storage = mod.storage[field] else {
            throw MetadataError.storageItemNotFound(prefix: module, item: field)
        }
        return storage
    }
    
    func hashers(forKey field: String, in module: String) throws -> [Hasher] {
        try _getStorageInfo(for: field, in: module).hashers()
    }
    
    func types(forKey field: String, in module: String) throws -> [DType] {
        try _getStorageInfo(for: field, in: module).types()
    }
    
    func value(defaultOf key: DStorageKey, registry: TypeRegistryProtocol) throws -> DValue {
        try _getStorageInfo(for: key.field, in: key.module).defaultValue(registry: registry)
    }
    
    func value<K: StorageKey>(defaultOf key: K, registry: TypeRegistryProtocol) throws -> K.Value {
        try _getStorageInfo(for: key.field, in: key.module).defaultValue(K.Value.self, registry: registry)
    }
}

// Constants
extension Metadata {
    private func _getConstantInfo<C: AnyConstant>(for constant: C) throws -> MetadataConstantInfo {
        guard let module = modulesByName[constant.module] else {
            throw MetadataError.moduleNotFound(name: constant.module)
        }
        guard let info = module.constants[constant.name] else {
            throw MetadataError.constantNotFound(module: constant.module, name: constant.name)
        }
        return info
    }
    
    public func value<C: DynamicConstant>(of constant: C, registry: TypeRegistryProtocol) throws -> DValue {
        return try _getConstantInfo(for: constant).get(registry: registry)
    }
    
    public func value<C: Constant>(of constant: C, registry: TypeRegistryProtocol) throws -> C.Value {
        return try _getConstantInfo(for: constant).parsed(C.Value.self, registry: registry)
    }
    
    public func type<C: AnyConstant>(of constant: C) throws -> DType {
        return try _getConstantInfo(for: constant).type
    }
}
