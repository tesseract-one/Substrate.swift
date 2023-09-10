//
//  StorageKey+StaticHelpers.swift
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

public extension PlainStorageKey where
    Self: ComplexStaticFrameType, TValue: ValidatableTypeStatic,
    ChildTypes == StorageKeyChildTypes
{
    @inlinable
    static var childTypes: ChildTypes { (keys: [], value: TValue.self) }
}

public extension PlainStorageKey where TValue: IdentifiableTypeStatic {
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .storage(keys: [], value: registry.def(TValue.self))
    }
}

public protocol MapStorageKey<TKH>: StaticStorageKey, IterableStorageKey where
    TParams == TKH.TKey, TIterator == MapStorageKeyIterator<Self>
{
    associatedtype TKH: TupleStorageKeyHasherPair
    var khPair: TKH { get }
    init(khPair: TKH)
}

public extension MapStorageKey {
    var key: TKH.TDecodedKey { khPair.decoded }
    var keys: (TKH.TDecodedKey) { khPair.decoded }
    var pathHash: Data { khPair.hash }
    
    init(_ params: TParams, runtime: any Runtime) throws {
        let kh = try TKH(key: params, runtime: runtime)
        self.init(khPair: kh)
    }
    
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws {
        let kh = try TKH(pairFrom: &decoder, runtime: runtime)
        self.init(khPair: kh)
    }
}

public extension MapStorageKey where
    Self: ComplexStaticFrameType, TKH.TKey: ValidatableTypeStatic,
    TValue: ValidatableTypeStatic, ChildTypes == StorageKeyChildTypes
{
    @inlinable
    static var childTypes: ChildTypes {
        (keys: [(TKH.THasher.self, TKH.TKey.self)], value: TValue.self)
    }
}

public extension MapStorageKey where TKH.TKey: IdentifiableTypeStatic, TValue: IdentifiableTypeStatic {
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .storage(keys: [(hasher: TKH.THasher.hasherType, type: registry.def(TKH.TKey.self))],
                 value: registry.def(TValue.self))
    }
}

public protocol DoubleMapStorageKey<TKH1, TKH2>: StaticStorageKey, IterableStorageKey where
    TParams == (TKH1.TKey, TKH2.TKey), TIterator == MapStorageKeyIterator<Self>,
    TKH1.TKey: IdentifiableTypeStatic, TKH2.TKey: IdentifiableTypeStatic
{
    associatedtype TKH1: TupleStorageKeyHasherPair
    associatedtype TKH2: TupleStorageKeyHasherPair
    
    var khPair1: TKH1 { get }
    var khPair2: TKH2 { get }

    init(khPair1: TKH1, khPair2: TKH2)
}

public extension DoubleMapStorageKey {
    var key1: TKH1.TDecodedKey { khPair1.decoded }
    var key2: TKH2.TDecodedKey { khPair2.decoded }
    var keys: (TKH1.TDecodedKey, TKH2.TDecodedKey) { (khPair1.decoded, khPair2.decoded) }
    
    var pathHash: Data { khPair1.hash + khPair2.hash }
    
    init(_ params: TParams, runtime: any Runtime) throws {
        let kh1 = try TKH1(key: params.0, runtime: runtime)
        let kh2 = try TKH2(key: params.1, runtime: runtime)
        self.init(khPair1: kh1, khPair2: kh2)
    }
    
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws {
        let kh1 = try TKH1(pairFrom: &decoder, runtime: runtime)
        let kh2 = try TKH2(pairFrom: &decoder, runtime: runtime)
        self.init(khPair1: kh1, khPair2: kh2)
    }
}

public extension DoubleMapStorageKey where
    Self: ComplexStaticFrameType, TKH1.TKey: ValidatableTypeStatic,
    TKH2.TKey: ValidatableTypeStatic, TValue: ValidatableTypeStatic,
    ChildTypes == StorageKeyChildTypes
{
    @inlinable
    static var childTypes: ChildTypes {
        (keys: [(TKH1.THasher.self, TKH1.TKey.self), (TKH2.THasher.self, TKH2.TKey.self)],
         value: TValue.self)
    }
}

public extension DoubleMapStorageKey where
    TKH1.TKey: IdentifiableTypeStatic, TKH2.TKey: IdentifiableTypeStatic,
    TValue: IdentifiableTypeStatic
{
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .storage(keys: [(hasher: TKH1.THasher.hasherType, type: registry.def(TKH1.TKey.self)),
                        (hasher: TKH2.THasher.hasherType, type: registry.def(TKH2.TKey.self))],
                 value: registry.def(TValue.self))
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
        public typealias TParam = K.TKH1.TKey
        
        public var hash: Data { MapStorageKeyIterator<K>.hash + khPair.hash }
        
        public let khPair: K.TKH1
        
        public init(key: TParam, runtime: any Runtime) throws {
            khPair = try K.TKH1(key: key, runtime: runtime)
        }
    }
    
    public typealias TIterator = DMIterator
    
    public func next(param: TIterator.TParam, runtime: Runtime) throws -> TIterator {
        try TIterator(key: param, runtime: runtime)
    }
}
