//
//  AnyStorageKey.swift
//  
//
//  Created by Yehor Popovych on 15/06/2023.
//

import Foundation
import ScaleCodec

public struct AnyStorageKey: IterableStorageKey {
    public typealias TParams = [Value<Void>]
    public typealias TBaseParams = (name: String, pallet: String)
    public typealias TValue = Value<RuntimeTypeId>
    public typealias TIterator = RootIterator
    
    public var pallet: String
    public var name: String
    public var path: [Component]
    
    public var values: [Value<Void>?] {
        path.map { $0.value }
    }
    
    public var hashes: [Data] {
        path.map { $0.hash }
    }
    
    public var hash: Data {
        hashes.reduce(self.prefix) { $0 + $1 }
    }
    
    public init(name: String, pallet: String, path: [Component]) {
        self.name = name
        self.pallet = pallet
        self.path = path
    }
    
    public init(base: (name: String, pallet: String), params: [Value<Void>], runtime: Runtime) throws {
        guard let (keys, _, _) = runtime.resolve(storage: base.name, pallet: base.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
        guard keys.count == params.count else {
            throw StorageKeyCodingError.badCountOfPathComponents(has: params.count,
                                                                 expected: keys.count)
        }
        var components = Array<Component>()
        components.reserveCapacity(params.count)
        for (key, val) in zip(keys, params) {
            let data = try runtime.encode(value: val, as: key.1)
            components.append(.full(val, key.0.hasher.hash(data: data)))
        }
        self.init(name: base.name, pallet: base.pallet, path: components)
    }
    
    public init<D: Decoder>(from decoder: inout D, base: (name: String, pallet: String), runtime: any Runtime) throws {
        guard let (keys, _, _) = runtime.resolve(storage: base.name, pallet: base.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
        let ownPrefix = Self.prefix(name: base.name, pallet: base.pallet)
        let gotPrefix = try decoder.decode(.fixed(UInt(ownPrefix.count)))
        guard ownPrefix == gotPrefix else {
            throw StorageKeyCodingError.badPrefix(has: gotPrefix, expected: ownPrefix)
        }
        let components: [Component] = try keys.map { (hash, tId) in
            let raw: Data = try decoder.decode(.fixed(UInt(hash.hasher.hashPartByteLength)))
            return hash.hasher.isConcat
                ? try .full(runtime.decodeValue(from: &decoder, id: tId).removingContext(), raw)
                : .hash(raw)
        }
        self.init(name: base.name, pallet: base.pallet, path: components)
    }
    
    public func decode<D: Decoder>(valueFrom decoder: inout D, runtime: Runtime) throws -> TValue {
        guard let (_, value, _) = runtime.resolve(storage: self.name, pallet: self.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
        }
        return try runtime.decodeValue(from: &decoder, id: value)
    }
    
    public static func defaultValue(
        base: (name: String, pallet: String),
        runtime: any Runtime
    ) throws -> Value<RuntimeTypeId> {
        guard let (_, vType, data) = runtime.resolve(storage: base.name, pallet: base.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
        return try runtime.decodeValue(from: data, id: vType)
    }
    
    public static func validate(base: (name: String, pallet: String), runtime: Runtime) throws {
        if runtime.resolve(storage: base.name, pallet: base.pallet) == nil {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
    }
}

public extension AnyStorageKey {
    enum Component {
        case hash(Data)
        case full(Value<Void>, Data)
        
        public var value: Value<Void>? {
            switch self {
            case .full(let val, _): return val
            default: return nil
            }
        }
        
        public var hash: Data {
            switch self {
            case .full(_, let hash): return hash
            case .hash(let hash): return hash
            }
        }
    }
}

public extension AnyStorageKey {
    struct RootIterator: StorageKeyRootIterator, IterableStorageKeyIterator {
        public typealias TParam = (name: String, pallet: String)
        public typealias TKey = AnyStorageKey
        public typealias TIterator = Iterator
        
        public let name: String
        public let pallet: String
        
        public var hash: Data {
            TKey.prefix(name: name, pallet: pallet)
        }
        
        public init(base param: (name: String, pallet: String)) {
            self.name = param.name
            self.pallet = param.pallet
        }
        
        public func next(param: Value<Void>, runtime: Runtime) throws -> TIterator {
            try TIterator(name: name, pallet: pallet, path: []).next(param: param, runtime: runtime)
        }
        
        public func decode<D: Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey {
            try TKey(from: &decoder, base: (name, pallet), runtime: runtime)
        }
    }
}

public extension AnyStorageKey {
    struct Iterator: StorageKeyIterator, IterableStorageKeyIterator {
        public typealias TParam = Value<Void>
        public typealias TKey = AnyStorageKey
        public typealias TIterator = Self
        
        public let name: String
        public let pallet: String
        public let path: [Component]
        
        public var hash: Data {
            path.reduce(TKey.prefix(name: name, pallet: pallet)) { $0 + $1.hash }
        }
        
        public init(name: String, pallet: String, path: [Component]) {
            self.name = name
            self.pallet = pallet
            self.path = path
        }
        
        public init(name: String, pallet: String, params: [Value<Void>], runtime: any Runtime) throws {
            guard let (keys, _, _) = runtime.resolve(storage: name, pallet: pallet) else {
                throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
            }
            guard keys.count > params.count else {
                throw StorageKeyCodingError.badCountOfPathComponents(has: params.count,
                                                                     expected: keys.count - 1)
            }
            var components = Array<Component>()
            components.reserveCapacity(params.count)
            for (key, val) in zip(keys, params) {
                let data = try runtime.encode(value: val, as: key.1)
                components.append(.full(val, key.0.hasher.hash(data: data)))
            }
            self.init(name: name, pallet: pallet, path: components)
        }
        
        public func next(param: Value<Void>, runtime: any Runtime) throws -> Self {
            guard let (keys, _, _) = runtime.resolve(storage: name, pallet: pallet) else {
                throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
            }
            guard keys.count > (path.count + 1) else {
                throw StorageKeyCodingError.badCountOfPathComponents(has: path.count + 1,
                                                                     expected: keys.count - 1)
            }
            let key = keys[path.count]
            let data = try runtime.encode(value: param, as: key.1)
            let newPath = path + [.full(param, key.0.hasher.hash(data: data))]
            return Self(name: name, pallet: pallet, path: newPath)
        }
        
        public func decode<D: Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey {
            try TKey(from: &decoder, base: (name, pallet), runtime: runtime)
        }
    }
}
