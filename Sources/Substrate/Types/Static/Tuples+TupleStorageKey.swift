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

public extension SomeTuple1 where Self: TupleStorageValidatableKeyPath {
    @inlinable
    static var validatablePath: [(hasher: StaticHasher.Type,
                                  type: ValidatableType.Type)]
    {
        [(T1.THasher.self, T1.TKey.self)]
    }
}

public extension SomeTuple1 where Self: TupleStorageIdentifiableKeyPath {
    @inlinable
    static var identifiablePath: [(key: TypeDefinition,
                                   hasher: LatestMetadata.StorageHasher)]
    {
        [(T1.TKey.definition, T1.THasher.hasherType)]
    }
}

public extension ListTuple
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

public extension ListTuple where
    Self: TupleStorageNKeyPath & TupleStorageValidatableKeyPath,
    DroppedFirst: TupleStorageValidatableKeyPath
{
    static var validatablePath: [(hasher: StaticHasher.Type,
                                  type: ValidatableType.Type)]
    {
        [(First.THasher.self, First.TKey.self)] + DroppedFirst.validatablePath
    }
}

public extension ListTuple where
    Self: TupleStorageNKeyPath & TupleStorageIdentifiableKeyPath,
    DroppedFirst: TupleStorageIdentifiableKeyPath
{
    @inlinable
    static var identifiablePath: [(key: TypeDefinition,
                                   hasher: LatestMetadata.StorageHasher)]
    {
        [(First.TKey.definition, First.THasher.hasherType)] + DroppedFirst.identifiablePath
    }
}

extension Tuple1: TupleStorageKeyPath where T1: TupleStorageKeyHasherPair {
    public typealias TKeys = Tuple1<T1.TKey>
    public typealias TDecodedKeys = Tuple1<T1.TDecodedKey>
    public typealias THashes = Tuple1<Data>
}
extension Tuple1: TupleStorageValidatableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: ValidatableType {}
extension Tuple1: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType {}
    
extension Tuple2: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple2<T1.TKey, T2.TKey>
    public typealias TDecodedKeys = Tuple2<T1.TDecodedKey, T2.TDecodedKey>
    public typealias THashes = Tuple2<Data, Data>
}
extension Tuple2: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType {}
extension Tuple2: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType {}

extension Tuple3: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple3<T1.TKey, T2.TKey, T3.TKey>
    public typealias TDecodedKeys = Tuple3<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey>
    public typealias THashes = Tuple3<Data, Data, Data>
}
extension Tuple3: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType {}
extension Tuple3: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType {}

extension Tuple4: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple4<T1.TKey, T2.TKey, T3.TKey, T4.TKey>
    public typealias TDecodedKeys = Tuple4<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                           T4.TDecodedKey>
    public typealias THashes = Tuple4<Data, Data, Data, Data>
}
extension Tuple4: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType {}
extension Tuple4: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType {}

extension Tuple5: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple5<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey>
    public typealias TDecodedKeys = Tuple5<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                           T4.TDecodedKey, T5.TDecodedKey>
    public typealias THashes = Tuple5<Data, Data, Data, Data, Data>
}
extension Tuple5: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType {}
extension Tuple5: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType {}

extension Tuple6: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple6<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey>
    public typealias TDecodedKeys = Tuple6<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                           T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey>
    public typealias THashes = Tuple6<Data, Data, Data, Data, Data, Data>
}
extension Tuple6: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType {}
extension Tuple6: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType {}

extension Tuple7: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple7<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                    T7.TKey>
    public typealias TDecodedKeys = Tuple7<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                           T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                           T7.TDecodedKey>
    public typealias THashes = Tuple7<Data, Data, Data, Data, Data, Data, Data>
}
extension Tuple7: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType {}
extension Tuple7: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType {}

extension Tuple8: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple8<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                    T7.TKey, T8.TKey>
    public typealias TDecodedKeys = Tuple8<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                           T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                           T7.TDecodedKey, T8.TDecodedKey>
    public typealias THashes = Tuple8<Data, Data, Data, Data, Data, Data, Data, Data>
}
extension Tuple8: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType {}
extension Tuple8: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType {}

extension Tuple9: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple9<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                    T7.TKey, T8.TKey, T9.TKey>
    public typealias TDecodedKeys = Tuple9<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                           T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                           T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey>
    public typealias THashes = Tuple9<Data, Data, Data, Data, Data, Data, Data, Data, Data>
}
extension Tuple9: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType {}
extension Tuple9: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType {}

extension Tuple10: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair, T10: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple10<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                     T7.TKey, T8.TKey, T9.TKey, T10.TKey>
    public typealias TDecodedKeys = Tuple10<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                            T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                            T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey,
                                            T10.TDecodedKey>
    public typealias THashes = Tuple10<Data, Data, Data, Data, Data, Data, Data, Data, Data,
                                       Data>
}
extension Tuple10: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType,
    T10.TKey: ValidatableType {}
extension Tuple10: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType,
    T10.TKey: IdentifiableType {}

extension Tuple11: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair, T10: TupleStorageKeyHasherPair,
    T11: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple11<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                     T7.TKey, T8.TKey, T9.TKey, T10.TKey, T11.TKey>
    public typealias TDecodedKeys = Tuple11<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                            T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                            T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey,
                                            T10.TDecodedKey, T11.TDecodedKey>
    public typealias THashes = Tuple11<Data, Data, Data, Data, Data, Data, Data, Data, Data,
                                       Data, Data>
}
extension Tuple11: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType,
    T10.TKey: ValidatableType, T11.TKey: ValidatableType {}
extension Tuple11: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType,
    T10.TKey: IdentifiableType, T11.TKey: IdentifiableType {}

extension Tuple12: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair, T10: TupleStorageKeyHasherPair,
    T11: TupleStorageKeyHasherPair, T12: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple12<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                     T7.TKey, T8.TKey, T9.TKey, T10.TKey, T11.TKey, T12.TKey>
    public typealias TDecodedKeys = Tuple12<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                            T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                            T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey,
                                            T10.TDecodedKey, T11.TDecodedKey, T12.TDecodedKey>
    public typealias THashes = Tuple12<Data, Data, Data, Data, Data, Data, Data, Data, Data,
                                       Data, Data, Data>
}
extension Tuple12: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType,
    T10.TKey: ValidatableType, T11.TKey: ValidatableType,
    T12.TKey: ValidatableType {}
extension Tuple12: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType,
    T10.TKey: IdentifiableType, T11.TKey: IdentifiableType,
    T12.TKey: IdentifiableType {}

extension Tuple13: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair, T10: TupleStorageKeyHasherPair,
    T11: TupleStorageKeyHasherPair, T12: TupleStorageKeyHasherPair,
    T13: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple13<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                     T7.TKey, T8.TKey, T9.TKey, T10.TKey, T11.TKey, T12.TKey,
                                     T13.TKey>
    public typealias TDecodedKeys = Tuple13<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                            T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                            T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey,
                                            T10.TDecodedKey, T11.TDecodedKey, T12.TDecodedKey,
                                            T13.TDecodedKey>
    public typealias THashes = Tuple13<Data, Data, Data, Data, Data, Data, Data, Data, Data,
                                       Data, Data, Data, Data>
}
extension Tuple13: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType,
    T10.TKey: ValidatableType, T11.TKey: ValidatableType,
    T12.TKey: ValidatableType, T13.TKey: ValidatableType {}
extension Tuple13: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType,
    T10.TKey: IdentifiableType, T11.TKey: IdentifiableType,
    T12.TKey: IdentifiableType, T13.TKey: IdentifiableType {}

extension Tuple14: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair, T10: TupleStorageKeyHasherPair,
    T11: TupleStorageKeyHasherPair, T12: TupleStorageKeyHasherPair,
    T13: TupleStorageKeyHasherPair, T14: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple14<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                     T7.TKey, T8.TKey, T9.TKey, T10.TKey, T11.TKey, T12.TKey,
                                     T13.TKey, T14.TKey>
    public typealias TDecodedKeys = Tuple14<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                            T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                            T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey,
                                            T10.TDecodedKey, T11.TDecodedKey, T12.TDecodedKey,
                                            T13.TDecodedKey, T14.TDecodedKey>
    public typealias THashes = Tuple14<Data, Data, Data, Data, Data, Data, Data, Data, Data,
                                       Data, Data, Data, Data, Data>
}
extension Tuple14: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType,
    T10.TKey: ValidatableType, T11.TKey: ValidatableType,
    T12.TKey: ValidatableType, T13.TKey: ValidatableType,
    T14.TKey: ValidatableType {}
extension Tuple14: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType,
    T10.TKey: IdentifiableType, T11.TKey: IdentifiableType,
    T12.TKey: IdentifiableType, T13.TKey: IdentifiableType,
    T14.TKey: IdentifiableType {}

extension Tuple15: TupleStorageNKeyPath, TupleStorageKeyPath where
    T1: TupleStorageKeyHasherPair, T2: TupleStorageKeyHasherPair,
    T3: TupleStorageKeyHasherPair, T4: TupleStorageKeyHasherPair,
    T5: TupleStorageKeyHasherPair, T6: TupleStorageKeyHasherPair,
    T7: TupleStorageKeyHasherPair, T8: TupleStorageKeyHasherPair,
    T9: TupleStorageKeyHasherPair, T10: TupleStorageKeyHasherPair,
    T11: TupleStorageKeyHasherPair, T12: TupleStorageKeyHasherPair,
    T13: TupleStorageKeyHasherPair, T14: TupleStorageKeyHasherPair,
    T15: TupleStorageKeyHasherPair
{
    public typealias TKeys = Tuple15<T1.TKey, T2.TKey, T3.TKey, T4.TKey, T5.TKey, T6.TKey,
                                     T7.TKey, T8.TKey, T9.TKey, T10.TKey, T11.TKey, T12.TKey,
                                     T13.TKey, T14.TKey, T15.TKey>
    public typealias TDecodedKeys = Tuple15<T1.TDecodedKey, T2.TDecodedKey, T3.TDecodedKey,
                                            T4.TDecodedKey, T5.TDecodedKey, T6.TDecodedKey,
                                            T7.TDecodedKey, T8.TDecodedKey, T9.TDecodedKey,
                                            T10.TDecodedKey, T11.TDecodedKey, T12.TDecodedKey,
                                            T13.TDecodedKey, T14.TDecodedKey, T15.TDecodedKey>
    public typealias THashes = Tuple15<Data, Data, Data, Data, Data, Data, Data, Data, Data,
                                       Data, Data, Data, Data, Data, Data>
}
extension Tuple15: TupleStorageValidatableKeyPath where
    Self: TupleStorageNKeyPath, T1.TKey: ValidatableType,
    T2.TKey: ValidatableType, T3.TKey: ValidatableType,
    T4.TKey: ValidatableType, T5.TKey: ValidatableType,
    T6.TKey: ValidatableType, T7.TKey: ValidatableType,
    T8.TKey: ValidatableType, T9.TKey: ValidatableType,
    T10.TKey: ValidatableType, T11.TKey: ValidatableType,
    T12.TKey: ValidatableType, T13.TKey: ValidatableType,
    T14.TKey: ValidatableType, T15.TKey: ValidatableType {}
extension Tuple15: TupleStorageIdentifiableKeyPath where
    Self: TupleStorageKeyPath, T1.TKey: IdentifiableType,
    T2.TKey: IdentifiableType, T3.TKey: IdentifiableType,
    T4.TKey: IdentifiableType, T5.TKey: IdentifiableType,
    T6.TKey: IdentifiableType, T7.TKey: IdentifiableType,
    T8.TKey: IdentifiableType, T9.TKey: IdentifiableType,
    T10.TKey: IdentifiableType, T11.TKey: IdentifiableType,
    T12.TKey: IdentifiableType, T13.TKey: IdentifiableType,
    T14.TKey: IdentifiableType, T15.TKey: IdentifiableType {}
