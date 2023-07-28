//
//  Tuples+StorageKey.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation
import ScaleCodec
import Tuples

public protocol TupleStorageKeyHasherPair {
    associatedtype THasher: StaticHasher
    associatedtype TKey: RuntimeEncodable
    
    init(key: TKey, hash: Data)
    init(key: TKey, runtime: any Runtime) throws
    init<D: ScaleCodec.Decoder>(pairFrom decoder: inout D, runtime: any Runtime) throws
    
    var hash: Data { get }
}

public protocol TupleStorageKeyPath: LinkedTuple
    where First: TupleStorageKeyHasherPair, Last: TupleStorageKeyHasherPair
{
    associatedtype TKeys: LinkedTuple where TKeys.First == First.TKey, TKeys.Last == Last.TKey
    
    init(keys: TKeys, runtime: any Runtime) throws
    init<D: ScaleCodec.Decoder>(pairsFrom decoder: inout D, runtime: any Runtime) throws
    
    var hash: Data { get }
}

public protocol TupleStorageNKeyPath: TupleStorageKeyPath where DroppedFirst: TupleStorageKeyPath {}

public extension TupleStorageKeyHasherPair {
    init(key: TKey, runtime: any Runtime) throws {
        let encoded = try runtime.encode(value: key)
        let hash = THasher.instance.hash(data: encoded)
        self.init(key: key, hash: hash)
    }
}

public protocol TupleStorageKey<TPath, TValue>: StaticStorageKey {
    associatedtype TPath: TupleStorageKeyPath
}

public extension SomeTuple1 where
    Self: TupleStorageKeyPath, TKeys: SomeTuple1, TKeys.T1 == T1.TKey
{
    var hash: Data { first.hash }
    
    init(keys: TKeys, runtime: any Runtime) throws {
        try self.init(T1(key: keys.first, runtime: runtime))
    }
    
    init<D: ScaleCodec.Decoder>(pairsFrom decoder: inout D, runtime: any Runtime) throws {
        try self.init(T1(pairFrom: &decoder, runtime: runtime))
    }
}

public extension LinkedTuple
    where Self: TupleStorageNKeyPath,
          DroppedFirst.TKeys == TKeys.DroppedFirst,
          First.TKey == TKeys.First
{
    var hash: Data { first.hash + dropFirst.hash }
    
    init(keys: TKeys, runtime: any Runtime) throws {
        let first = try First(key: keys.first, runtime: runtime)
        try self.init(first: first, last: DroppedFirst(keys: keys.dropFirst, runtime: runtime))
    }
    
    init<D: ScaleCodec.Decoder>(pairsFrom decoder: inout D, runtime: any Runtime) throws {
        let first = try First(pairFrom: &decoder, runtime: runtime)
        try self.init(first: first, last: DroppedFirst(pairsFrom: &decoder, runtime: runtime))
    }
}

public struct FixedKH<K: RuntimeCodable, H: StaticFixedHasher>: TupleStorageKeyHasherPair {
    public typealias THasher = H
    public typealias TKey = K
    
    public let hash: Data
    public let key: K?
    
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
    
    public let hash: Data
    public let key: K
    
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

public struct TupleStorageKeyRootIterator<Key: TupleStorageKey> {
    public struct Iterator<Prev: StorageKeyIterator, Path: TupleStorageKeyPath> {
        public let previous: Prev
        public let key: Path.First
        
        public init(prev: Prev, key: Path.First) {
            self.previous = prev
            self.key = key
        }
    }
    
    public init() {}
}

extension TupleStorageKeyRootIterator: StorageKeyRootIterator {
    public typealias TParam = Void
    public typealias TKey = Key
    public init(base: Void) { self.init() }
}

extension TupleStorageKeyRootIterator: IterableStorageKeyIterator
    where Key.TPath: TupleStorageNKeyPath
{
    public typealias TIterator = Iterator<Self, Key.TPath>
    
    public func next(param: TIterator.TParam, runtime: Runtime) throws -> TIterator {
        try TIterator(prev: self, key: Key.TPath.First(key: param, runtime: runtime))
    }
}

extension TupleStorageKeyRootIterator.Iterator: StorageKeyIterator {
    public typealias TParam = Path.TKeys.First
    public typealias TKey = Key
    
    public var hash: Data { get throws { try previous.hash + key.hash } }
}

extension TupleStorageKeyRootIterator.Iterator: IterableStorageKeyIterator
    where Path: TupleStorageNKeyPath
{
    public typealias TIterator =
        TupleStorageKeyRootIterator.Iterator<Self, Path.DroppedFirst>
    
    public func next(param: TIterator.TParam, runtime: Runtime) throws -> TIterator {
        try TIterator(prev: self, key: Path.DroppedFirst.First(key: param, runtime: runtime))
    }
}

extension Tuple1: TupleStorageKeyPath where T1: TupleStorageKeyHasherPair {
    public typealias TKeys = Tuple1<T1.TKey>
}

extension Tuple2: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple2<T1.TKey, T2.TKey>
}
