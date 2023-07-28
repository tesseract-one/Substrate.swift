//
//  Tuples+TupleStorageKey.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation
import ScaleCodec
import Tuples

public extension SomeTuple1 where
    Self: TupleStorageKeyPath, TKeys: SomeTuple1, THashes: SomeTuple1,
    TDecodedKeys: SomeTuple1, TKeys.T1 == T1.TKey, TDecodedKeys.T1 == T1.TDecodedKey
{
    var hash: Data { first.hash }
    var keys: TDecodedKeys { TDecodedKeys(first.decoded) }
    var hashes: THashes { THashes(first.hash) }
    
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
          DroppedFirst.THashes == THashes.DroppedFirst,
          DroppedFirst.TDecodedKeys == TDecodedKeys.DroppedFirst,
          First.TKey == TKeys.First, First.TDecodedKey == TDecodedKeys.First
{
    var hash: Data { first.hash + dropFirst.hash }
    var keys: TDecodedKeys { TDecodedKeys(first: first.decoded, last: dropFirst.keys) }
    var hashes: THashes { THashes(first: first.hash, last: dropFirst.hashes) }
    
    init(keys: TKeys, runtime: any Runtime) throws {
        let first = try First(key: keys.first, runtime: runtime)
        try self.init(first: first, last: DroppedFirst(keys: keys.dropFirst, runtime: runtime))
    }
    
    init<D: ScaleCodec.Decoder>(pairsFrom decoder: inout D, runtime: any Runtime) throws {
        let first = try First(pairFrom: &decoder, runtime: runtime)
        try self.init(first: first, last: DroppedFirst(pairsFrom: &decoder, runtime: runtime))
    }
}

extension Tuple1: TupleStorageKeyPath where T1: TupleStorageKeyHasherPair {
    public typealias TKeys = Tuple1<T1.TKey>
    public typealias TDecodedKeys = Tuple1<T1.TDecodedKey>
    public typealias THashes = Tuple1<Data>
}

extension Tuple2: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple2<T1.TKey, T2.TKey>
    public typealias TDecodedKeys = Tuple2<T1.TDecodedKey, T2.TDecodedKey>
    public typealias THashes = Tuple2<Data, Data>
}
