//
//  StorageKeyHelpers.swift
//  
//
//  Created by Yehor Popovych on 16/08/2023.
//

import Foundation
import ScaleCodec

public protocol PlainStorageKey: StaticStorageKey where TParams == Void {
    init()
}

public extension PlainStorageKey {
    init(_ params: TParams, runtime: any Runtime) throws {
        self.init()
    }
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws {
        self.init()
    }
    var pathHash: Data { Data() }
}

public protocol MapStorageKey: StaticStorageKey, IterableStorageKey where
    TParams == TKeyHasher.TKey, TIterator == MapStorageKeyIterator<Self>
{
    associatedtype TKeyHasher: TupleStorageKeyHasherPair
    var keyHasherPair: TKeyHasher { get }
    init(pair: TKeyHasher)
}

public extension MapStorageKey {
    var key: TKeyHasher.TDecodedKey { keyHasherPair.decoded }
    var pathHash: Data { keyHasherPair.hash }
    
    init(_ params: TParams, runtime: any Runtime) throws {
        let kh = try TKeyHasher(key: params, runtime: runtime)
        self.init(pair: kh)
    }
    
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws {
        let kh = try TKeyHasher(pairFrom: &decoder, runtime: runtime)
        self.init(pair: kh)
    }
}

public protocol DoubleMapStorageKey: StaticStorageKey, IterableStorageKey where
    TParams == (TKeyHasher1.TKey, TKeyHasher2.TKey), TIterator == MapStorageKeyIterator<Self>
{
    associatedtype TKeyHasher1: TupleStorageKeyHasherPair
    associatedtype TKeyHasher2: TupleStorageKeyHasherPair
    
    var keyHasherPair1: TKeyHasher1 { get }
    var keyHasherPair2: TKeyHasher1 { get }
    
    init(pair1: TKeyHasher1, pair2: TKeyHasher2)
}

public extension DoubleMapStorageKey {
    var key1: TKeyHasher1.TDecodedKey { keyHasherPair1.decoded }
    var key2: TKeyHasher1.TDecodedKey { keyHasherPair2.decoded }
    
    var pathHash: Data { keyHasherPair1.hash + keyHasherPair2.hash }
    
    init(_ params: TParams, runtime: any Runtime) throws {
        let kh1 = try TKeyHasher1(key: params.0, runtime: runtime)
        let kh2 = try TKeyHasher2(key: params.1, runtime: runtime)
        self.init(pair1: kh1, pair2: kh2)
    }
    
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws {
        let kh1 = try TKeyHasher1(pairFrom: &decoder, runtime: runtime)
        let kh2 = try TKeyHasher2(pairFrom: &decoder, runtime: runtime)
        self.init(pair1: kh1, pair2: kh2)
    }
}

public struct MapStorageKeyIterator<K: StaticStorageKey & IterableStorageKey>: StorageKeyRootIterator {
    public typealias TKey = K
    public typealias TParam = K.TBaseParams
    public init(base: K.TBaseParams) {}
}

extension MapStorageKeyIterator: IterableStorageKeyIterator where K: DoubleMapStorageKey {
    public struct DMIterator: StorageKeyIterator {
        public typealias TKey = K
        public typealias TParam = K.TKeyHasher1.TKey
        
        public var hash: Data { MapStorageKeyIterator<K>.hash + keyHasherPair.hash }
        
        public let keyHasherPair: K.TKeyHasher1
        
        public init(key: TParam, runtime: any Runtime) throws {
            keyHasherPair = try K.TKeyHasher1(key: key, runtime: runtime)
        }
    }
    
    public typealias TIterator = DMIterator
    
    public func next(param: TIterator.TParam, runtime: Runtime) throws -> TIterator {
        try TIterator(key: param, runtime: runtime)
    }
}
