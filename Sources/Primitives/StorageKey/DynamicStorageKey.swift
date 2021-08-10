//
//  DynamicStorageKey.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec

// Generic storage key
public struct DStorageKey: AnyStorageKey, ScaleDynamicCodable {
    public let module: String
    public let field: String
    public let hashes: [Data]?
    
    public var path: [Any?] { _path }
    
    private let _path: [DValue]
    
    public init(module: String, field: String, path: [DValue], hashes: [Data]? = nil) {
        self.module = module
        self._path = path
        self.field = field
        self.hashes = hashes
    }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let prefix = try Self.prefix(from: decoder)
        let info = try registry.info(forKey: prefix)
        try self.init(module: info.module, field: info.field, decoder: decoder, registry: registry)
    }
    
    public init(module: String, field: String, decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self.module = module
        self.field = field
        
        let hashers = try registry.hashers(forKey: field, in: module)
        let types = try registry.types(forKey: field, in: module)
        
        var path: [DValue] = []
        var hashes: [Data] = []
        for (hasher, type) in zip(hashers, types.dropLast()) {
            let (key, hash) = try Self._decode(hasher: hasher, type: type, decoder: decoder, registry: registry)
            path.append(key)
            hashes.append(hash)
        }
        self._path = path
        self.hashes = hashes
    }
    
    public func iterator() throws -> DStorageKey {
        guard _path.count > 0 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: module, field: field, count: _path.count, expected: 1
            )
        }
        return DStorageKey(module: module,
                           field: field,
                           path: _path.dropLast(),
                           hashes: hashes?.dropLast())
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: field, in: module)
        let types = try registry.types(forKey: field, in: module)
        
        guard hashers.count >= _path.count else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: module, field: field, count: _path.count, expected: hashers.count
            )
        }
        guard types.count > _path.count else {
            throw TypeRegistryError.storageItemBadPathTypesCount(
                module: module, field: field, count: types.count-1, expected: _path.count
            )
        }
        
        try encoder.encode(self._prefix(), .fixed(Self.prefixSize))
        let hashes: [Data?] = self.hashes ?? Array(repeating: nil, count: _path.count)
        for (idx, (key, hash)) in zip(_path, hashes).enumerated() {
            let data = try self._hash(hasher: hashers[idx],
                                      hash: hash, key: key, type: types[idx],
                                      registry: registry)
            try encoder.encode(data, .fixed(UInt(data.count)))
        }
    }
    
    public func decode(valueFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws -> Any {
        let types = try registry.types(forKey: field, in: module)
        // TODO: Better decoding (DYNAMIC)
        return try registry.decode(dynamic: types.last!, from: decoder)
    }
}

private extension DStorageKey {
    func _prefix() -> Data {
        Self.prefix(module: module, field: field)
    }
    
    static func _decode(
        hasher: Hasher, type: DType, decoder: ScaleDecoder, registry: TypeRegistryProtocol
    ) throws -> (DValue, Data) {
        let hash: Data = try decoder.decode(.fixed(UInt(hasher.hashPartByteLength)))
        var key: DValue = .null
        if hasher.isConcat {
            key = try registry.decode(dynamic: type, from: decoder)
        }
        return (key, hash)
    }
    
    func _hash(
        hasher: Hasher, hash: Data?, key: DValue, type: DType, registry: TypeRegistryProtocol
    ) throws -> Data {
        if let hash = hash, !hasher.isConcat {
            return hash
        } else {
            if case .null = key {
                throw TypeRegistryError.storageItemEmptyItem(module: module, field: field)
            }
            let encoder = SCALE.default.encoder()
            try registry.encode(dynamic: key, type: type, in: encoder)
            return hasher.hash(data: encoder.output)
        }
    }
}
