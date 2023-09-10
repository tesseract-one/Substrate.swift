//
//  AnyStorageKey.swift
//  
//
//  Created by Yehor Popovych on 15/06/2023.
//

import Foundation
import ScaleCodec

public typealias AnyValueStorageKey = AnyStorageKey<Value<TypeDefinition>>

public struct AnyStorageKey<Val: RuntimeDynamicDecodable>: DynamicStorageKey, CustomStringConvertible {
    public typealias TParams = [ValueRepresentable]
    public typealias TBaseParams = (name: String, pallet: String)
    public typealias TValue = Val
    public typealias TIterator = Iterator.Root
    
    public var pallet: String
    public var name: String
    public var path: [Component]
    
    public var anyValues: [ValueRepresentable?] {
        path.map { $0.value }
    }
    
    public var values: [Value<TypeDefinition>?] {
        path.map { $0.value.flatMap{$0 as? Value<TypeDefinition>} }
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
    
    public init(base: (name: String, pallet: String), params: [ValueRepresentable], runtime: Runtime) throws {
        guard let (keys, _, _) = runtime.resolve(storage: base.name, pallet: base.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
        guard keys.count == params.count else {
            throw StorageKeyCodingError.badCountOfPathComponents(has: params.count,
                                                                 expected: keys.count)
        }
        let components: [Component] = try zip(keys, params).map { (key, val) in
            let value = try val.asValue(of: key.type, in: runtime)
            let data = try runtime.encode(value: value)
            return .full(val, key.hasher.hasher.hash(data: data))
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
        var skippable = decoder.skippable()
        let components: [Component] = try keys.map { (hash, type) in
            let raw: Data = try decoder.decode(.fixed(UInt(hash.hasher.hashPartByteLength)))
            try skippable.skip(count: raw.count)
            if hash.hasher.isConcat {
                let lengthBefore = decoder.length
                let value = try runtime.decodeValue(from: &decoder, type: type).removingContext()
                let valData = try skippable.read(count: lengthBefore - decoder.length) // read encoded value
                return .full(value, raw + valData)
            } else {
                return .hash(raw)
            }
        }
        self.init(name: base.name, pallet: base.pallet, path: components)
    }
    
    public func decode<D: Decoder>(valueFrom decoder: inout D, runtime: Runtime) throws -> TValue {
        return try runtime.decode(from: &decoder) {
            guard let (_, value, _) = runtime.resolve(storage: self.name, pallet: self.pallet) else {
                throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
            }
            return value
        }
    }
    
    public static func defaultValue(
        base: (name: String, pallet: String),
        runtime: any Runtime
    ) throws -> TValue {
        guard let (_, vType, data) = runtime.resolve(storage: base.name, pallet: base.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
        return try runtime.decode(from: data, type: vType)
    }
    
    public static func validate(base: (name: String, pallet: String), runtime: Runtime) throws {
        if runtime.resolve(storage: base.name, pallet: base.pallet) == nil {
            throw StorageKeyCodingError.storageNotFound(name: base.name, pallet: base.pallet)
        }
    }
    
    public var description: String {
        "<\(pallet).\(name)>\(path)"
    }
}

public extension AnyStorageKey {
    enum Component: CustomStringConvertible {
        case hash(Data)
        case full(ValueRepresentable, Data)
        
        public var value: ValueRepresentable? {
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
        
        public var description: String {
            switch self {
            case .full(let val, let hash): return "(hash: \(hash.hex()), value: \(val))"
            case .hash(let hash): return hash.hex()
            }
        }
    }
}

public extension AnyStorageKey {
    struct Iterator: DynamicStorageKeyIterator, CustomStringConvertible {
        public typealias TParam = ValueRepresentable
        public typealias TKey = AnyStorageKey<Val>
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
        
        public init(name: String, pallet: String, params: [ValueRepresentable], runtime: any Runtime) throws {
            guard let (keys, _, _) = runtime.resolve(storage: name, pallet: pallet) else {
                throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
            }
            guard keys.count > params.count else {
                throw StorageKeyCodingError.badCountOfPathComponents(has: params.count,
                                                                     expected: keys.count - 1)
            }
            let components: [Component] = try zip(keys, params).map { (key, val) in
                let value = try val.asValue(of: key.type, in: runtime)
                let data = try runtime.encode(value: value)
                return .full(val, key.hasher.hasher.hash(data: data))
            }
            self.init(name: name, pallet: pallet, path: components)
        }
        
        public func next(param: ValueRepresentable, runtime: any Runtime) throws -> Self {
            guard let (keys, _, _) = runtime.resolve(storage: name, pallet: pallet) else {
                throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
            }
            guard keys.count > (path.count + 1) else {
                throw StorageKeyCodingError.badCountOfPathComponents(has: path.count + 1,
                                                                     expected: keys.count - 1)
            }
            let key = keys[path.count]
            let value = try param.asValue(of: key.type, in: runtime)
            let data = try runtime.encode(value: value)
            let newPath = path + [.full(param, key.hasher.hasher.hash(data: data))]
            return Self(name: name, pallet: pallet, path: newPath)
        }
        
        public func decode<D: Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey {
            try TKey(from: &decoder, base: (name, pallet), runtime: runtime)
        }
        
        public var description: String {
            "I<\(pallet).\(name)>\(path)"
        }
    }
}

public extension AnyStorageKey.Iterator {
    struct Root: StorageKeyRootIterator, IterableStorageKeyIterator {
        public typealias TParam = (name: String, pallet: String)
        public typealias TKey = AnyStorageKey<Val>
        public typealias TIterator = AnyStorageKey<Val>.Iterator
        
        public let name: String
        public let pallet: String
        
        public var hash: Data {
            TKey.prefix(name: name, pallet: pallet)
        }
        
        public init(base param: (name: String, pallet: String)) {
            self.name = param.name
            self.pallet = param.pallet
        }
        
        public func next(param: ValueRepresentable, runtime: Runtime) throws -> TIterator {
            try TIterator(name: name, pallet: pallet, path: []).next(param: param, runtime: runtime)
        }
        
        public func decode<D: Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey {
            try TKey(from: &decoder, base: (name, pallet), runtime: runtime)
        }
        
        public var description: String {
            "I<\(pallet).\(name)>[]"
        }
    }
}
