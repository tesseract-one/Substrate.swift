//
//  DynamicStorageKey.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec

public protocol AnyStorageKey {
    associatedtype Value
    var module: String { get }
    var field: String { get }
}

// Generic storage key
public struct DStorageKey: DynamicStorageKey {
    public let module: String
    public let field: String
    public let path: [DValue]
    public let hash: [Data]?
    
    public init(module: String, field: String, path: [DValue], hash: [Data]? = nil) {
        self.module = module
        self.path = path
        self.field = field
        self.hash = hash
    }
}

public protocol DynamicStorageKey: AnyStorageKey where Value == DValue {
    var path: [DValue] { get }
    var hash: [Data]? { get }
    
    init(module: String, field: String, path: [DValue], hash: [Data]?)
    init(
        module: String, field: String, types: [DType], h1: Hasher?,
        h2: Hasher?, decoder: ScaleDecoder, registry: TypeRegistryProtocol
    ) throws
    func iteratorKey(h1: Hasher?, type: DType?, registry: TypeRegistryProtocol) throws -> Data
    func key(h1: Hasher?, h2: Hasher?, types: [DType], registry: TypeRegistryProtocol) throws -> Data
}

extension DynamicStorageKey {
    public init(
        module: String, field: String, types: [DType], h1: Hasher?,
        h2: Hasher?, decoder: ScaleDecoder, registry: TypeRegistryProtocol
    ) throws {
        switch types.count {
        case 0: self.init(module: module, field: field, path: [], hash: nil)
        case 1:
            guard let h1 = h1 else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Plain", expected: "Map"
                )
            }
            let (key, hash) = try Self._decode(hasher: h1, type: types[0], decoder: decoder, registry: registry)
            self.init(module: module, field: field, path: [key], hash: [hash])
        case 2:
            guard let h1 = h1 else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Plain", expected: "Map"
                )
            }
            guard let h2 = h2 else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Map", expected: "DoubleMap"
                )
            }
            let (key1, hash1) = try Self._decode(hasher: h1, type: types[0], decoder: decoder, registry: registry)
            let (key2, hash2) = try Self._decode(hasher: h2, type: types[1], decoder: decoder, registry: registry)
            self.init(module: module, field: field, path: [key1, key2], hash: [hash1, hash2])
        default:
            throw TypeRegistryError.storageItemBadPathTypesCount(
                module: module, field: field, count: types.count, expected: 2
            )
        }
    }
    
    public func iteratorKey(h1: Hasher?, type: DType?, registry: TypeRegistryProtocol) throws -> Data {
        switch path.count {
        case 1:
            guard h1 == nil, type == nil else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "DoubleMap", expected: "Map"
                )
            }
            return Data()
        case 2:
            guard let h1 = h1, let type = type else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Map", expected: "DoubleMap"
                )
            }
            return try _hash(hasher: h1, hash: hash?[0], key: path[0], type: type, registry: registry)
        default:
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Plain", expected: "Map"
            )
        }
    }
    
    public func key(h1: Hasher?, h2: Hasher?, types: [DType], registry: TypeRegistryProtocol) throws -> Data {
        guard types.count == path.count else {
            throw TypeRegistryError.storageItemBadPathTypesCount(
                module: module, field: field, count: types.count, expected: path.count
            )
        }
        var data = Data()
        if path.count > 0 {
            guard let h1 = h1 else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Plain", expected: "Map"
                )
            }
            data += try _hash(hasher: h1, hash: hash?[0], key: path[0], type: types[0], registry: registry)
        }
        if path.count > 1 {
            guard let h2 = h2 else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Map", expected: "DoubleMap"
                )
            }
            data += try _hash(hasher: h2, hash: hash?[1], key: path[1], type: types[1], registry: registry)
        }
        return data
    }
}

private extension DynamicStorageKey {
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
