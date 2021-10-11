//
//  StaticStorageKey.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol StaticStorageKey: AnyStorageKey {
    static var MODULE: String { get }
    static var FIELD: String { get }
    
    init(parsingPathFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

public protocol StorageKey: StaticStorageKey, ScaleDynamicDecodable {
    associatedtype Value: ScaleDynamicDecodable
    associatedtype Module: ModuleProtocol
}

public protocol IterableStorageKey: StorageKey {
    associatedtype IteratorKey
    
    func iterator(registry: TypeRegistryProtocol) throws -> Data
    static func iterator(key: IteratorKey, registry: TypeRegistryProtocol) throws -> Data
}

public protocol PlainStorageKey: StorageKey {
    init()
}

public protocol MapStorageKey: IterableStorageKey where IteratorKey == Void {
    associatedtype K: ScaleDynamicCodable
    
    var key: K? { get }
    var hash: Data? { get }
    
    init(key: K)
    init(key: K?, hash: Data)
}

public protocol DoubleMapStorageKey: IterableStorageKey where IteratorKey == K1 {
    associatedtype K1: ScaleDynamicCodable
    associatedtype K2: ScaleDynamicCodable
    
    var key: (K1?, K2?) { get }
    var hash: (Data, Data)? { get }
    
    init(key: (K1, K2))
    init(key: (K1?, K2?), hash: (Data, Data))
}

extension StaticStorageKey {
    public var module: String { return Self.MODULE }
    public var field: String { return Self.FIELD }
}

extension StorageKey {
    public static var MODULE: String { return Module.NAME }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try Self._checkPrefix(decoder: decoder)
        try self.init(parsingPathFrom: decoder, registry: registry)
    }
    
    public func decode(valueFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws -> Any {
        return try Self.Value.init(from: decoder, registry: registry)
    }
}

extension PlainStorageKey {
    public init(parsingPathFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: Self.FIELD, in: Self.MODULE)
        guard hashers.count == 0 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: Self.MODULE, field: Self.FIELD, count: 0, expected: hashers.count
            )
        }
        self.init()
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: field, in: module)
        guard hashers.count == 0 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: module, field: field, count: 0, expected: hashers.count
            )
        }
        try encoder.encode(Self._prefix(), .fixed(Self.prefixSize))
    }
    
    public var path: [Any?] { [] }
    public var hashes: [Data]? { [] }
}

extension MapStorageKey {
    public init(parsingPathFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: Self.FIELD, in: Self.MODULE)
        guard hashers.count == 1 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: Self.MODULE, field: Self.FIELD, count: 1, expected: hashers.count
            )
        }
        let (key, hash): (K?, Data) = try Self._decode(hasher: hashers[0], decoder: decoder, registry: registry)
        self.init(key: key, hash: hash)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: field, in: module)
        guard hashers.count == 1 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: module, field: field, count: 1, expected: hashers.count
            )
        }
        try encoder.encode(Self._prefix(), .fixed(Self.prefixSize))
        let hashed = try Self._hash(hasher: hashers[0], hash: hash, key: key, registry: registry)
        try encoder.encode(hashed, .fixed(UInt(hashed.count)))
    }
    
    public func iterator(registry: TypeRegistryProtocol) throws -> Data {
        return try Self.iterator(key: (), registry: registry)
    }
    
    public static func iterator(key: Void, registry: TypeRegistryProtocol) throws -> Data {
        return Self._prefix()
    }
    
    public var path: [Any?] { [key] }
    public var hashes: [Data]? { hash.map { [$0] } }
}

extension DoubleMapStorageKey {
    public init(parsingPathFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: Self.FIELD, in: Self.MODULE)
        guard hashers.count == 2 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: Self.MODULE, field: Self.FIELD, count: 2, expected: hashers.count
            )
        }
        let (key1, hash1): (K1?, Data) = try Self._decode(hasher: hashers[0], decoder: decoder, registry: registry)
        let (key2, hash2): (K2?, Data) = try Self._decode(hasher: hashers[1], decoder: decoder, registry: registry)
        self.init(key: (key1, key2), hash: (hash1, hash2))
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let hashers = try registry.hashers(forKey: field, in: module)
        guard hashers.count == 2 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: module, field: field, count: 2, expected: hashers.count
            )
        }
        try encoder.encode(Self._prefix(), .fixed(Self.prefixSize))
        let hash1 = try Self._hash(hasher: hashers[0], hash: hash?.0, key: key.0, registry: registry)
        let hash2 = try Self._hash(hasher: hashers[1], hash: hash?.1, key: key.1, registry: registry)
        try encoder.encode(hash1, .fixed(UInt(hash1.count)))
        try encoder.encode(hash2, .fixed(UInt(hash2.count)))
    }
    
    public func iterator(registry: TypeRegistryProtocol) throws -> Data {
        let hashers = try registry.hashers(forKey: field, in: module)
        guard hashers.count == 2 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: module, field: field, count: 2, expected: hashers.count
            )
        }
        return try Self._prefix()
            + Self._hash(hasher: hashers[0], hash: hash?.0, key: key.0, registry: registry)
    }
    
    public static func iterator(key: IteratorKey, registry: TypeRegistryProtocol) throws -> Data {
        let hashers = try registry.hashers(forKey: Self.FIELD, in: Self.MODULE)
        guard hashers.count == 2 else {
            throw TypeRegistryError.storageItemBadPathCount(
                module: Self.MODULE, field: Self.FIELD, count: 2, expected: hashers.count
            )
        }
        return try Self._prefix()
            + Self._hash(hasher: hashers[0], hash: nil, key: key, registry: registry)
    }
    
    public var path: [Any?] { [key.0, key.1] }
    public var hashes: [Data]? { hash.map { [$0.0, $0.1] } }
}

private extension StaticStorageKey {
    static func _prefix() -> Data {
        Self.prefix(module: Self.MODULE, field: Self.FIELD)
    }
    
    static func _checkPrefix(decoder: ScaleDecoder) throws {
        let parsedPrefix = try decoder.decode(Data.self, .fixed(Self.prefixSize))
        let prefix = Self._prefix()
        guard prefix == parsedPrefix else {
            throw TypeRegistryError.storageItemDecodingBadPrefix(
                module: Self.MODULE, field: Self.FIELD, prefix: parsedPrefix, expected: prefix
            )
        }
    }
    
    static func _decode<K: ScaleDynamicDecodable>(
        hasher: Hasher, decoder: ScaleDecoder, registry: TypeRegistryProtocol
    ) throws -> (K?, Data) {
        let hash: Data = try decoder.decode(.fixed(UInt(hasher.hashPartByteLength)))
        var key: K? = nil
        if hasher.isConcat {
            key = try K(from: decoder, registry: registry)
        }
        return (key, hash)
    }
    
    static func _hash<K: ScaleDynamicEncodable>(
        hasher: Hasher, hash: Data?, key: K?, registry: TypeRegistryProtocol
    ) throws -> Data {
        if let hash = hash, !hasher.isConcat {
            return hash
        } else if let key = key {
            let encoder = SCALE.default.encoder()
            try key.encode(in: encoder, registry: registry)
            return hasher.hash(data: encoder.output)
        } else {
            throw TypeRegistryError.storageItemEmptyItem(module: Self.MODULE, field: Self.FIELD)
        }
    }
}
