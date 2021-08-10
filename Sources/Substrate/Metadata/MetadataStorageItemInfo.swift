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
    
    public func hashers() -> [Hasher] {
        switch type {
        case .plain: return []
        case .map(hasher: let h, key: _, value: _, unused: _):
            return [h.hasher]
        case .doubleMap(hasher: let h1, key1: _, key2: _, value: _, key2_hasher: let h2):
            return [h1.hasher, h2.hasher]
        }
    }
    
    public func types() -> [DType] {
        return pathTypes + [valueType]
    }
    
    public func defaultValue(registry: TypeRegistryProtocol) throws -> DValue {
        try registry.decode(dynamic: valueType, from: SCALE.default.decoder(data: defaultValue))
    }
    
    public func defaultValue<T: ScaleDynamicDecodable>(_ t: T.Type, registry: TypeRegistryProtocol) throws -> T {
        try T(from: SCALE.default.decoder(data: defaultValue), registry: registry)
    }
}
