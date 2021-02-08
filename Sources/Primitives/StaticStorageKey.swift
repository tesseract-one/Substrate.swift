//
//  StaticStorageKey.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol StaticStorageKey: AnyStorageKey where Value: ScaleDynamicDecodable {
    associatedtype Module: ModuleProtocol
    static var MODULE: String { get }
    static var FIELD: String { get }
    
    init(h1: Hasher?, h2: Hasher?, from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
    func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data
}

public protocol IterableStaticStorageKey: StaticStorageKey {
     func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data
}

public protocol PlainStorageKey: StaticStorageKey {
    init()
}

public protocol MapStorageKey: IterableStaticStorageKey {
    associatedtype K: ScaleDynamicCodable
    
    var path: K? { get }
    var hash: Data? { get }
    
    init(path: K?, hash: Data)
}

public protocol DoubleMapStorageKey: IterableStaticStorageKey {
    associatedtype K1: ScaleDynamicCodable
    associatedtype K2: ScaleDynamicCodable
    
    var path: (K1?, K2?) { get }
    var hash: (Data, Data)? { get }
    
    init(path: (K1?, K2?), hash: (Data, Data))
}

extension StaticStorageKey {
    public static var MODULE: String { return Module.NAME }
    public var module: String { return Self.MODULE }
    public var field: String { return Self.FIELD }
}

extension PlainStorageKey {
    public init(h1: Hasher?, h2: Hasher?, from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self.init()
    }
    
    public func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data { Data() }
}

extension MapStorageKey {
    public init(h1: Hasher?, h2: Hasher?, from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: Self.MODULE, field: Self.FIELD, type: "Plain", expected: "Map"
            )
        }
        let (key, hash): (K?, Data) = try Self._decode(hasher: h1, decoder: decoder, registry: registry)
        self.init(path: key, hash: hash)
    }
    
    public func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard h1 == nil else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "DoubleMap", expected: "Map"
            )
        }
        return Data()
    }
    
    public func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Plain", expected: "Map"
            )
        }
        return try _hash(hasher: h1, hash: hash, key: path, registry: registry)
    }
}

extension DoubleMapStorageKey {
    public init(h1: Hasher?, h2: Hasher?, from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: Self.MODULE, field: Self.FIELD, type: "Plain", expected: "Map"
            )
        }
        guard let h2 = h2 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: Self.MODULE, field: Self.FIELD, type: "Map", expected: "DoubleMap"
            )
        }
        let (key1, hash1): (K1?, Data) = try Self._decode(hasher: h1, decoder: decoder, registry: registry)
        let (key2, hash2): (K2?, Data) = try Self._decode(hasher: h2, decoder: decoder, registry: registry)
        self.init(path: (key1, key2), hash: (hash1, hash2))
    }
    
    public func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Map", expected: "DoubleMap"
            )
        }
        return try _hash(hasher: h1, hash: hash?.0, key: path.0, registry: registry)
    }
    
    public func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Plain", expected: "DoubleMap"
            )
        }
        guard let h2 = h2 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Map", expected: "DoubleMap"
            )
        }
        let hash1 = try _hash(hasher: h1, hash: hash?.0, key: path.0, registry: registry)
        let hash2 = try _hash(hasher: h2, hash: hash?.1, key: path.1, registry: registry)
        return hash1 + hash2
    }
}

private extension IterableStaticStorageKey {
    static func _decode<K: ScaleDynamicCodable>(
        hasher: Hasher, decoder: ScaleDecoder, registry: TypeRegistryProtocol
    ) throws -> (K?, Data) {
        let hash: Data = try decoder.decode(.fixed(UInt(hasher.hashPartByteLength)))
        var key: K? = nil
        if hasher.isConcat {
            key = try K(from: decoder, registry: registry)
        }
        return (key, hash)
    }
    
    func _hash<K: ScaleDynamicCodable>(
        hasher: Hasher, hash: Data?, key: K?, registry: TypeRegistryProtocol
    ) throws -> Data {
        if let hash = hash, !hasher.isConcat {
            return hash
        } else if let key = key {
            let encoder = SCALE.default.encoder()
            try key.encode(in: encoder, registry: registry)
            return hasher.hash(data: encoder.output)
        } else {
            throw TypeRegistryError.storageItemEmptyItem(module: module, field: field)
        }
    }
}
