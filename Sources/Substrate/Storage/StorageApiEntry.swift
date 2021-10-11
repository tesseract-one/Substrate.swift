//
//  StorageApiEntry.swift
//  
//
//  Created by Yehor Popovych on 06.10.2021.
//

import Foundation
#if !COCOAPODS
import SubstratePrimitives
#endif

public struct StorageApiEntry<S: SubstrateProtocol, Key: StorageKey> {
    public let substrate: S
    
    public init(substrate: S) {
        self.substrate = substrate
    }
}

extension StorageApiEntry where Key: PlainStorageKey  {
    public func get(at hash: S.R.THash? = nil,
                    timeout: TimeInterval? = nil,
                    _ cb: @escaping SRpcApiCallback<Key.Value>) {
        substrate.rpc.state.getStorage(for: Key(), at: hash, timeout: timeout, cb)
    }
}

extension StorageApiEntry where Key: MapStorageKey {
    public func get(key: Key.K, at hash: S.R.THash? = nil,
                    timeout: TimeInterval? = nil,
                    _ cb: @escaping SRpcApiCallback<Key.Value>) {
        substrate.rpc.state.getStorage(for: Key(key: key), at: hash, timeout: timeout, cb)
    }
    
    public func keys(pageSize: UInt32? = nil,
                     from: Key.K? = nil,
                     at hash: S.R.THash? = nil,
                     timeout: TimeInterval? = nil) -> StorageApiKeyIterator<Key, S> {
       return StorageApiKeyIterator(substrate: substrate, key: (), page: pageSize,
                                    from: from.map(Key.init), at: hash, timeout: timeout)
    }
    
    public func entries(pageSize: UInt32? = nil,
                        from: Key.K? = nil,
                        at hash: S.R.THash? = nil,
                        timeout: TimeInterval? = nil) -> StorageApiEntryIterator<Key, S> {
        let keyIter = keys(pageSize: pageSize, from: from, at: hash, timeout: timeout)
        return StorageApiEntryIterator(iterator: keyIter)
    }
}

extension StorageApiEntry where Key: DoubleMapStorageKey {
    public func get(key: (Key.K1, Key.K2), at hash: S.R.THash? = nil,
                    timeout: TimeInterval? = nil,
                    _ cb: @escaping SRpcApiCallback<Key.Value>) {
        substrate.rpc.state.getStorage(for: Key(key: key), at: hash, timeout: timeout, cb)
    }
    
    public func keys(key: Key.K1,
                     pageSize: UInt32? = nil,
                     from: Key.K2? = nil,
                     at hash: S.R.THash? = nil,
                     timeout: TimeInterval? = nil) -> StorageApiKeyIterator<Key, S> {
       return StorageApiKeyIterator(substrate: substrate, key: key, page: pageSize,
                                    from: from.map{Key(key: (key, $0))},
                                    at: hash, timeout: timeout)
    }
    
    public func entries(key: Key.K1,
                        pageSize: UInt32? = nil,
                        from: Key.K2? = nil,
                        at hash: S.R.THash? = nil,
                        timeout: TimeInterval? = nil) -> StorageApiEntryIterator<Key, S> {
        let keyIter = keys(key: key, pageSize: pageSize, from: from, at: hash, timeout: timeout)
        return StorageApiEntryIterator(iterator: keyIter)
    }
}

public struct StorageApiKeyIterator<Key: IterableStorageKey, S: SubstrateProtocol> {
    public let substrate: S
    public let key: Key.IteratorKey
    public let pageSize: UInt32
    public let from: Key?
    public let hash: S.R.THash?
    public let timeout: TimeInterval?
    
    public init(substrate: S, key: Key.IteratorKey, page: UInt32? = nil, from: Key? = nil, at hash: S.R.THash? = nil, timeout: TimeInterval? = nil) {
        self.substrate = substrate
        self.pageSize = page ?? 100
        self.from = from
        self.hash = hash
        self.key = key
        self.timeout = timeout
    }
    
    public func next(_ cb: @escaping (SRpcApiResult<[Key]>, Self?) -> Void) {
        substrate.rpc.state.getKeysPaged(for: key,
                                         count: pageSize,
                                         startKey: from, at: hash, timeout: timeout) { res in
            switch res {
            case .failure(let err): cb(.failure(err), nil)
            case .success(let keys):
                let next = keys.count == self.pageSize
                    ? Self(substrate: substrate, key: key, page: pageSize,
                           from: keys.last!, at: hash, timeout: timeout)
                    : nil
                cb(.success(keys), next)
            }
        }
    }
}

public struct StorageApiEntryIterator<Key: IterableStorageKey, S: SubstrateProtocol> {
    private let keysIterator: StorageApiKeyIterator<Key, S>
    
    public init(iterator: StorageApiKeyIterator<Key, S>) {
        self.keysIterator = iterator
    }
    
    private func fetch(fetched: [(Key, Key.Value)],
                       current: Key,
                       left: [Key],
                       _ cb: @escaping SRpcApiCallback<[(Key, Key.Value)]>) {
        keysIterator.substrate.rpc.state.getStorage(for: current,
                                                    at: keysIterator.hash,
                                                    timeout: keysIterator.timeout) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success(let val):
                var newFetched = fetched
                newFetched.append((current, val))
                if (left.count == 0) {
                    cb(.success(newFetched))
                } else {
                    self.fetch(fetched: newFetched, current: left.first!, left: Array(left.dropFirst()), cb)
                }
            }
        }
    }
    
    public func next(_ cb: @escaping (SRpcApiResult<[(Key, Key.Value)]>, Self?) -> Void) {
        keysIterator.next { (res, next) in
            switch res {
            case .failure(let err): cb(.failure(err), nil)
            case .success(let keys):
                if (keys.count == 0) {
                    cb(.success([]), nil)
                } else {
                    self.fetch(fetched: [], current: keys.first!, left: Array(keys.dropFirst())) {
                        cb($0, next.map(Self.init))
                    }
                }
            }
        }
    }
}


// TODO: Implement dynamic key iterators. (DYNAMIC)
