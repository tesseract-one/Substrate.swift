//
//  MetadataStorageItemInfo.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
#if !COCOAPODS
import SubstratePrimitives
#endif

public class MetadataStorageItemInfo {
    public let prefix: String
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryType
    public let valueType: DType
    public let pathTypes: [DType]
    public let defaultValue: Data
    public let documentation: String
    
    public init(prefix: String, runtime: RuntimeStorageItemMetadata) throws {
        self.prefix = prefix
        name = runtime.name
        type = runtime.type
        valueType = try DType.fromMeta(type: runtime.type.value)
        pathTypes = try runtime.type.path.map { try DType.fromMeta(type: $0) }
        defaultValue = runtime.defaultValue
        modifier = runtime.modifier
        documentation = runtime.documentation.joined(separator: "\n")
    }
    
    public func prefixHash() -> Data {
        var data = HXX128.hasher.hash(data: prefix.data(using: .utf8)!)
        data.append(HXX128.hasher.hash(data: name.data(using: .utf8)!))
        return data
    }
    
    public func prefixHashLength() -> Int {
        return 2 * HXX128.hashPartByteLength
    }
    
    public func defaultValue(registry: TypeRegistryProtocol) throws -> DValue {
        try registry.decode(dynamic: valueType, from: SCALE.default.decoder(data: defaultValue))
    }
    
    public func defaultValue<T: ScaleDynamicDecodable>(_ t: T.Type, registry: TypeRegistryProtocol) throws -> T {
        try registry.decode(static: t, as: valueType, from: SCALE.default.decoder(data: defaultValue))
    }
    
    public func hash<K: DynamicStorageKey>(of key: K, registry: TypeRegistryProtocol) throws -> Data {
        let prefix = prefixHash()
        switch type {
        case .plain(_):
            return try prefix + key.key(h1: nil, h2: nil, types: pathTypes, registry: registry)
        case .map(hasher: let h1, key: _, value: _, unused: _):
            return try prefix + key.key(h1: h1.hasher, h2: nil, types: pathTypes, registry: registry)
        case .doubleMap(hasher: let h1 , key1: _, key2: _, value: _, key2_hasher: let h2):
            return try prefix + key.key(h1: h1.hasher, h2: h2.hasher, types: pathTypes, registry: registry)
        }
    }
    
    public func hash<K: StaticStorageKey>(of key: K, registry: TypeRegistryProtocol) throws -> Data {
        let prefix = prefixHash()
        switch type {
        case .plain(_):
            return try prefix + key.key(h1: nil, h2: nil, registry: registry)
        case .map(hasher: let h1, key: _, value: _, unused: _):
            return try prefix + key.key(h1: h1.hasher, h2: nil, registry: registry)
        case .doubleMap(hasher: let h1 , key1: _, key2: _, value: _, key2_hasher: let h2):
            return try prefix + key.key(h1: h1.hasher, h2: h2.hasher, registry: registry)
        }
    }
    
    public func hash<K: DynamicStorageKey>(iteratorOf key: K, registry: TypeRegistryProtocol) throws -> Data {
        let prefix = prefixHash()
        switch type {
        case .plain(_):
            return try prefix + key.iteratorKey(h1: nil, type: nil, registry: registry)
        case .map(hasher: _, key: _, value: _, unused: _):
            return try prefix + key.iteratorKey(h1: nil, type: nil, registry: registry)
        case .doubleMap(hasher: let h1 , key1: _, key2: _, value: _, key2_hasher: _):
            return try prefix + key.iteratorKey(h1: h1.hasher, type: pathTypes[0], registry: registry)
        }
    }
    
    public func hash<K: IterableStaticStorageKey>(iteratorOf key: K, registry: TypeRegistryProtocol) throws -> Data {
        let prefix = prefixHash()
        switch type {
        case .plain(_):
            return try prefix + key.iteratorKey(h1: nil, registry: registry)
        case .map(hasher: _, key: _, value: _, unused: _):
            return try prefix + key.iteratorKey(h1: nil, registry: registry)
        case .doubleMap(hasher: let h1 , key1: _, key2: _, value: _, key2_hasher: _):
            return try prefix + key.iteratorKey(h1: h1.hasher, registry: registry)
        }
    }
}
