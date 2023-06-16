//
//  StorageEntry.swift
//  
//
//  Created by Yehor Popovych on 09/06/2023.
//

import Foundation

public struct StorageEntry<S: SomeSubstrate, Key: StorageKey> {
    public let substrate: S
    public let params: Key.TBaseParams
   
    public init(
        substrate: S,
        params: Key.TBaseParams
    ) throws {
        try Key.validate(base: params, runtime: substrate.runtime)
        self.params = params
        self.substrate = substrate
    }
    
    public func key(_ params: Key.TParams) throws -> Key {
        try Key(base: self.params, params: params, runtime: substrate.runtime)
    }
    
    public func size(
        key: Key,
        at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> UInt64 {
        try await substrate.client.storage(size: key, at: hash, runtime: substrate.runtime)
    }
    
    public func size(
        _ params: Key.TParams,
        at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> UInt64 {
        try await size(key: key(params), at: hash)
    }
    
    public func value(
        key: Key,
        at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> Key.TValue? {
        try await substrate.client.storage(value: key, at: hash, runtime: substrate.runtime)
    }
    
    public func value(
        _ params: Key.TParams,
        at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> Key.TValue? {
        try await value(key: key(params), at: hash)
    }
    
    public func defaultValue() throws -> Key.TValue {
        try Key.defaultValue(base: params, runtime: substrate.runtime)
    }
    
    public func valueOrDefault(
        key: Key,
        at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> Key.TValue {
        if let value = try await value(key: key, at: hash) {
            return value
        }
        return try defaultValue()
    }
    
    public func valueOrDefault(
        _ params: Key.TParams,
        at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> Key.TValue {
        try await valueOrDefault(key: key(params), at: hash)
    }
}

public extension StorageEntry {
    struct Iterator<Iter: StorageKeyIterator> where Iter.TKey == Key {
        public let substrate: S
        public let iterator: Iter
        
        public init(substrate: S, iterator: Iter) {
            self.substrate = substrate
            self.iterator = iterator
        }
        
        public func keys(
            page: Int = 20, at hash: S.RC.TBlock.THeader.THasher.THash? = nil
        ) -> AsyncThrowingStream<Iter.TKey, Error> {
            var buffer: [Iter.TKey] = []
            buffer.reserveCapacity(page)
            var lastKey: Iter.TKey? = nil
            var atHash: S.RC.TBlock.THeader.THasher.THash? = hash
            return AsyncThrowingStream<Iter.TKey, Error> {
                if atHash == nil {
                    atHash = try await substrate.client.block(hash: nil, runtime: substrate.runtime)!
                }
                if buffer.count > 0 { return buffer.removeFirst() }
                let new = try await substrate.client.storage(keys: iterator,
                                                             count: page,
                                                             startKey: lastKey,
                                                             at: atHash,
                                                             runtime: substrate.runtime)
                lastKey = new.last
                guard new.count > 0 else { return nil }
                buffer.append(contentsOf: new)
                return buffer.removeFirst()
            }
        }
        
        public func entries(
            page: Int = 20, at hash: S.RC.TBlock.THeader.THasher.THash? = nil
        ) -> AsyncThrowingStream<(Iter.TKey, Iter.TKey.TValue), Error> {
            var buffer: [(Iter.TKey, Iter.TKey.TValue)] = []
            buffer.reserveCapacity(page)
            var lastKey: Iter.TKey? = nil
            var atHash: S.RC.TBlock.THeader.THasher.THash? = hash
            return AsyncThrowingStream<(Iter.TKey, Iter.TKey.TValue), Error> {
                if atHash == nil {
                    atHash = try await substrate.client.block(hash: nil, runtime: substrate.runtime)!
                }
                if buffer.count > 0 { return buffer.removeFirst() }
                var finished: Bool = false
                repeat {
                    let new = try await substrate.client.storage(keys: iterator,
                                                                 count: page,
                                                                 startKey: lastKey,
                                                                 at: atHash,
                                                                 runtime: substrate.runtime)
                    lastKey = new.last
                    guard new.count > 0 else { return nil }
                    let changes = try await substrate.client.storage(changes: new,
                                                                     at: atHash,
                                                                     runtime: substrate.runtime)
                    let filtered = changes.compactMap { $0.1 != nil ? ($0.0, $0.1!) : nil }
                    if filtered.count > 0 {
                        buffer.append(contentsOf: filtered)
                        finished = true
                    }
                } while (!finished)
                return buffer.removeFirst()
            }
        }
    }
}

public extension StorageEntry where Key: IterableStorageKey {
    var iterator: Key.TIterator { Key.TIterator(base: params) }
    
    func entries(
        page: Int = 20, at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) -> AsyncThrowingStream<(Key, Key.TValue), Error> {
        Iterator(substrate: substrate, iterator: iterator).entries(page: page, at: hash)
    }
    
    func keys(
        page: Int = 20, at hash: S.RC.TBlock.THeader.THasher.THash? = nil
    ) -> AsyncThrowingStream<Key, Error> {
        Iterator(substrate: substrate, iterator: iterator).keys(page: page, at: hash)
    }
}

public extension StorageEntry where Key: IterableStorageKey, Key.TIterator: IterableStorageKeyIterator {
    func filter(
        _ param: Key.TIterator.TIterator.TParam
    ) throws -> Iterator<Key.TIterator.TIterator> {
        try Iterator(substrate: substrate,
                     iterator: iterator.next(param: param, runtime: substrate.runtime))
    }
}

public extension StorageEntry where Key == AnyStorageKey {
    func size(at hash: S.RC.TBlock.THeader.THasher.THash? = nil) async throws -> UInt64 {
        try await size(key: Key(name: params.name, pallet: params.pallet, path: []), at: hash)
    }
    
    func value(at hash: S.RC.TBlock.THeader.THasher.THash? = nil) async throws -> Key.TValue? {
        try await value(key: Key(name: params.name, pallet: params.pallet, path: []), at: hash)
    }
    
    func valueOrDefault(at hash: S.RC.TBlock.THeader.THasher.THash? = nil) async throws -> Key.TValue {
        try await valueOrDefault(key: Key(name: params.name, pallet: params.pallet, path: []), at: hash)
    }
    
    func filter(params: [Key.Iterator.TParam]) throws -> Iterator<Key.Iterator> {
        try Iterator(substrate: substrate,
                     iterator: Key.Iterator(name: self.params.name,
                                            pallet: self.params.pallet,
                                            params: params,
                                            runtime: substrate.runtime))
    }
}

public extension StorageEntry where Key.TParams == Void {
    func size(at hash: S.RC.TBlock.THeader.THasher.THash? = nil) async throws -> UInt64 {
        try await size(key: Key(base: params, params: (), runtime: substrate.runtime), at: hash)
    }
    
    func value(at hash: S.RC.TBlock.THeader.THasher.THash? = nil) async throws -> Key.TValue? {
        try await value(key: Key(base: params, params: (), runtime: substrate.runtime), at: hash)
    }
    
    func valueOrDefault(at hash: S.RC.TBlock.THeader.THasher.THash? = nil) async throws -> Key.TValue {
        try await valueOrDefault(key: Key(base: params, params: (), runtime: substrate.runtime), at: hash)
    }
}

public extension StorageEntry.Iterator where Iter: IterableStorageKeyIterator {
    func filter(
        _ param: Iter.TIterator.TParam
    ) throws -> StorageEntry.Iterator<Iter.TIterator> {
        try StorageEntry.Iterator<_>(substrate: substrate,
                                     iterator: iterator.next(param: param,
                                                             runtime: substrate.runtime))
    }
}
