//
//  TupleStorageKey.swift
//  
//
//  Created by Yehor Popovych on 28/07/2023.
//

import Foundation
import Tuples
import ScaleCodec

public protocol TupleStorageKeyHasherPair {
    associatedtype THasher: StaticHasher
    associatedtype TKey: RuntimeEncodable
    associatedtype TDecodedKey
    
    init(key: TKey, hash: Data)
    init(key: TKey, runtime: any Runtime) throws
    init<D: ScaleCodec.Decoder>(pairFrom decoder: inout D, runtime: any Runtime) throws
    
    var hash: Data { get }
    var decoded: TDecodedKey { get }
}

public protocol TupleStorageKeyPath: LinkedTuple
    where First: TupleStorageKeyHasherPair, Last: TupleStorageKeyHasherPair
{
    associatedtype TKeys: LinkedTuple where
        TKeys.First == First.TKey, TKeys.Last == Last.TKey
    associatedtype TDecodedKeys: LinkedTuple where
        TDecodedKeys.First == First.TDecodedKey, TDecodedKeys.Last == Last.TDecodedKey
    associatedtype THashes: LinkedTuple & OneTypeTuple<Data> where
        THashes.First == Data, THashes.Last == Data
    
    init(keys: TKeys, runtime: any Runtime) throws
    init<D: ScaleCodec.Decoder>(pairsFrom decoder: inout D, runtime: any Runtime) throws
    
    var keys: TDecodedKeys { get }
    var hashes: THashes { get }
    
    var hash: Data { get }
}

public protocol TupleStorageNKeyPath: TupleStorageKeyPath where DroppedFirst: TupleStorageKeyPath {}

public protocol TupleStorageKeyBase<TPath, TValue>: StaticStorageKey
    where TParams == TPath.TKeys.STuple
{
    associatedtype TPath: TupleStorageKeyPath
    var path: TPath { get }
    var keys: TPath.TDecodedKeys.STuple { get }
    var hashes: TPath.THashes.STuple { get }
    init(path: TPath)
}

public extension TupleStorageKeyBase {
    var keys: TPath.TDecodedKeys.STuple { path.keys.tuple }
    var hashes: TPath.THashes.STuple { path.hashes.tuple }
    var pathHash: Data { get throws { path.hash }}
    
    init(_ params: TParams, runtime: any Runtime) throws {
        try self.init(path: TPath(keys: TPath.TKeys(params), runtime: runtime))
    }
    
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws {
        try self.init(path: TPath(pairsFrom: &decoder, runtime: runtime))
    }
}

public protocol TupleStorageKey<TPath, TValue>: TupleStorageKeyBase, IterableStorageKey
    where TIterator == TupleStorageKeyIterator<Self> {}

public extension TupleStorageKeyHasherPair {
    init(key: TKey, runtime: any Runtime) throws {
        let encoded = try runtime.encode(value: key)
        let hash = THasher.instance.hash(data: encoded)
        self.init(key: key, hash: hash)
    }
}

public struct FixedKH<K: RuntimeEncodable, H: StaticFixedHasher>: TupleStorageKeyHasherPair {
    public typealias THasher = H
    public typealias TKey = K
    public typealias TDecodedKey = Void
    
    public let hash: Data
    public let key: K?
    public var decoded: Void { () }
    
    public init(key: TKey, hash: Data) {
        self.key = key
        self.hash = hash
    }
    
    public init<D: ScaleCodec.Decoder>(pairFrom decoder: inout D, runtime: Runtime) throws {
        self.key = nil
        self.hash = try decoder.decode(.fixed(UInt(H.bitWidth / 8)))
    }
}

public struct ConcatKH<K: RuntimeCodable, H: StaticConcatHasher>: TupleStorageKeyHasherPair {
    public typealias THasher = H
    public typealias TKey = K
    public typealias TDecodedKey = K
    
    public let hash: Data
    public let key: K
    public var decoded: K { key }
    
    public init(key: TKey, hash: Data) {
        self.key = key
        self.hash = hash
    }
    
    public init<D: ScaleCodec.Decoder>(pairFrom decoder: inout D, runtime: Runtime) throws {
        let hash: Data = try decoder.decode(.fixed(UInt(H.instance.hashPartByteLength)))
        var skippable = decoder.skippable()
        let lengthBefore = skippable.length
        self.key = try K(from: &skippable, runtime: runtime)
        let keyData = try decoder.decode(.fixed(UInt(lengthBefore - skippable.length)))
        self.hash = hash + keyData
    }
}

public struct TupleStorageKeyIterator<Key: TupleStorageKeyBase> {
    public struct SubIterator<Prev: StorageKeyIterator, Path: TupleStorageKeyPath> {
        public let previous: Prev
        public let key: Path.First
        
        public init(prev: Prev, key: Path.First) {
            self.previous = prev
            self.key = key
        }
    }
    
    public init() {}
}

extension TupleStorageKeyIterator: StorageKeyRootIterator {
    public typealias TParam = Void
    public typealias TKey = Key
    public init(base: Void) { self.init() }
}

extension TupleStorageKeyIterator: IterableStorageKeyIterator
    where Key.TPath: TupleStorageNKeyPath
{
    public typealias TIterator = SubIterator<Self, Key.TPath>
    
    public func next(param: TIterator.TParam, runtime: Runtime) throws -> TIterator {
        try TIterator(prev: self, key: Key.TPath.First(key: param, runtime: runtime))
    }
}

extension TupleStorageKeyIterator.SubIterator: StorageKeyIterator {
    public typealias TParam = Path.TKeys.First
    public typealias TKey = Key
    
    public var hash: Data { get throws { try previous.hash + key.hash } }
}

extension TupleStorageKeyIterator.SubIterator: IterableStorageKeyIterator
    where Path: TupleStorageNKeyPath
{
    public typealias TIterator =
        TupleStorageKeyIterator.SubIterator<Self, Path.DroppedFirst>
    
    public func next(param: TIterator.TParam, runtime: Runtime) throws -> TIterator {
        try TIterator(prev: self, key: Path.DroppedFirst.First(key: param, runtime: runtime))
    }
}
