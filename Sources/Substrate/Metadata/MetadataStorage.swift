//
//  MetadataStorage.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public class MetadataStorageItem {
    public let prefix: String
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryType
    public let valueType: SType
    public let pathTypes: [SType]
    public let defaultValue: Data
    public let documentation: String
    
    public init(prefix: String, runtime: RuntimeStorageItemMetadata) throws {
        self.prefix = prefix
        name = runtime.name
        type = runtime.type
        valueType = try SType(runtime.type.value)
        pathTypes = try runtime.type.path.map { try SType($0) }
        defaultValue = runtime.defaultValue
        modifier = runtime.modifier
        documentation = runtime.documentation.joined(separator: "\n")
    }
    
    public func prefixHash() -> Data {
        var data = HXX128.hasher.hash(data: prefix.data(using: .utf8)!)
        data.append(HXX128.hasher.hash(data: name.data(using: .utf8)!))
        return data
    }
    
    public func parsedDefault<T: ScaleDecodable>(_ t: T.Type) throws -> T {
        return try T(from: SCALE.default.decoder(data: defaultValue))
    }
    
    public func getDefault(with registry: TypeRegistry) throws -> ScaleRegistryDecodable {
        let decoder = SCALE.default.decoder(data: defaultValue)
        return try registry.metadata.decode(type: valueType, from: decoder, with: registry)
    }
    
    public func key(path: [ScaleRegistryEncodable], with registry: TypeRegistry) throws -> Data {
        switch type {
        case .plain(_):
//            guard path.count == 0 else {
//                throw TypeRegistryError.
//            }
            return prefixHash()
        case .map(hasher: let hasher, key: _, value: _, unused: _):
            //            guard path.count == 1 else {
            //                throw TypeRegistryError.
            //            }
            let encoder = SCALE.default.encoder()
            try registry.metadata.encode(value: path[0], type: pathTypes[0], in: encoder, with: registry)
            return prefixHash() + hasher.hasher.hash(data: encoder.output)
        case .doubleMap(hasher: let hasher1, key1: _, key2: _, value: _, key2_hasher: let hasher2):
            //            guard path.count == 2 else {
            //                throw TypeRegistryError.
            //            }
            let encoder1 = SCALE.default.encoder()
            try registry.metadata.encode(value: path[0], type: pathTypes[0], in: encoder1, with: registry)
            let encoder2 = SCALE.default.encoder()
            try registry.metadata.encode(value: path[1], type: pathTypes[1], in: encoder2, with: registry)
            return prefixHash() + hasher1.hasher.hash(data: encoder1.output) + hasher2.hasher.hash(data: encoder2.output)
        }
    }
}
