//
//  StorageKey.swift
//  
//
//  Created by Yehor Popovych on 08.03.2023.
//

import Foundation
import ScaleCodec

public protocol StorageKey<TValue> {
    associatedtype TValue
    
    var pallet: String { get }
    var name: String { get }
    
    func hash(registry: Registry) throws -> Data
    func decode(valueFrom decoder: ScaleDecoder, registry: Registry) throws -> TValue
}

extension StorageKey {
    public var prefix: Data { Self.prefix(name: self.name, pallet: self.pallet) }
    
    public static func prefix(name: String, pallet: String) -> Data {
        HXX128.hasher.hash(data: Data(pallet.utf8)) +
            HXX128.hasher.hash(data: Data(name.utf8))
    }
}

public protocol StaticStorageKey: StorageKey, RegistryScaleDecodable {
    static var pallet: String { get }
    static var name: String { get }
    
    init(decodingPath decoder: ScaleDecoder, registry: Registry) throws
    func encodePath(in encoder: ScaleEncoder, registry: Registry) throws
}

extension StaticStorageKey {
    public var pallet: String { Self.pallet }
    public var name: String { Self.name }
    
    public static var prefix: Data { Self.prefix(name: Self.name, pallet: Self.pallet) }
}

extension StaticStorageKey {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        let prefix = Self.prefix
        let decodedPrefix = try decoder.decode(.fixed(UInt(prefix.count)))
        guard decodedPrefix == prefix else {
            throw StorageKeyCodingError.badPrefix(has: decodedPrefix, expected: prefix)
        }
        try self.init(decodingPath: decoder, registry: registry)
    }
    
    public func hash(registry: Registry) throws -> Data {
        let encoder = registry.encoder()
        try self.encodePath(in: encoder, registry: registry)
        return self.prefix + encoder.output
    }
}

extension StaticStorageKey where TValue: RegistryScaleDecodable {
    public func decode(valueFrom decoder: ScaleDecoder, registry: Registry) throws -> TValue {
        try TValue(from: decoder, registry: registry)
    }
}

public struct DynamicStorageKey<C>: StorageKey {
    public typealias TValue = Value<RuntimeTypeId>
    
    public enum Component {
        case value(Value<C>)
        case hash(Data)
        case full(Value<C>, Data)
        
        public var value: Value<C>? {
            switch self {
            case .full(let val, _): return val
            case .value(let val): return val
            default: return nil
            }
        }
        
        public var hash: Data? {
            switch self {
            case .full(_, let hash): return hash
            case .hash(let hash): return hash
            default: return nil
            }
        }
    }
    
    public var pallet: String
    public var name: String
    public var path: [Component]
    
    public var values: [Value<C>?] {
        path.map { $0.value }
    }
    
    public var hashes: [Data?] {
        path.map { $0.hash }
    }
    
    public init(pallet: String, name: String, path: [Value<C>]) {
        self.pallet = pallet
        self.name = name
        self.path = path.map { .value($0) }
    }
    
    public func hash(registry: Registry) throws -> Data {
        try hashes(registry: registry).reduce(self.prefix) { data, hash in
            data + hash
        }
    }
    
    public func hashes(registry: Registry) throws -> [Data] {
        guard let (keys, _) = registry.resolve(storage: name, pallet: pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
        }
        guard keys.count == path.count else {
            throw StorageKeyCodingError.badCountOfPathComponents(has: path.count, expected: keys.count)
        }
        return try path.enumerated().map { idx, comp in
            switch comp {
            case .full(_, let hash): return hash
            case .hash(let hash): return hash
            case .value(let val):
                let encoder = registry.encoder()
                try val.encode(in: encoder, as: keys[idx].1, registry: registry)
                return keys[idx].0.hasher.hash(data: encoder.output)
            }
        }
    }
    
    public func decode(valueFrom decoder: ScaleDecoder, registry: Registry) throws -> TValue {
        guard let (_, value) = registry.resolve(storage: self.name, pallet: self.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
        }
        return try TValue(from: decoder, as: value, registry: registry)
    }
}

extension DynamicStorageKey where C == RuntimeTypeId {
    public init(from decoder: ScaleDecoder, pallet: String, name: String, registry: Registry) throws {
        guard let (keys, _) = registry.resolve(storage: name, pallet: pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
        }
        self.pallet = pallet
        self.name = name
        self.path = try keys.map { (hash, tId) in
            let raw: Data = try decoder.decode(.fixed(UInt(hash.hasher.hashPartByteLength)))
            return hash.hasher.isConcat
                ? try .full(registry.decode(from: decoder, type: tId), raw)
                : .hash(raw)
        }
    }
}

public enum StorageKeyCodingError: Error {
    case storageNotFound(name: String, pallet: String)
    case badCountOfPathComponents(has: Int, expected: Int)
    case badPrefix(has: Data, expected: Data)
}
