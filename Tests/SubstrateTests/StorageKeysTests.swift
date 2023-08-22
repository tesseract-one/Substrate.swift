//
//  StorageKeysTests.swift
//  
//
//  Created by Yehor Popovych on 15/07/2023.
//

import XCTest
import ScaleCodec
import Tuples
@testable import Substrate

final class StorageKeysTests: XCTestCase {
    func testEncDecAnyKey() throws {
        let keys = [
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a000003adc196911e491e08264834504a64ace1373f0c8ed5d57381ddf54a2f67a318fa42b1352681606d",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a000016d5103a6adeae4fc21ad1e5198cc0dc3b0f9f43a50f292678f63235ea321e59385d7ee45a720836",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00002a47718370fccca6c6332dd72fc6d33bf202a531e66cfaf46e6161640f91864f23f82b31b38c5f11",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00003635b95e2a31e59704b42c45250880695e6cec68c5adce35a0e2ec60ed46b77b734ad6020b991658",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00003ecb31e90f8870f218164fa6f9ce28792fb781185e8de4e6eaae34c0f545e5864952fe23c183df0c",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00004245138345ca3fd8aebb0211dbb07b4d335a657257b8ac5e53794c901e4f616d4a254f2490c43934",
            "0x5f3e4907f716ac89b6347d15ececedca8bde0a0ea8864605e3b68ed9cb2da01b50c62cd3172a7c6c041a00004f0f0dc89f14ad14767f36484b1e2acf5c265c7a64bfb46e95259c66a8189bbcd216195def436852"
        ]
        
        let runtime = try self.runtime()
        
        for hex in keys {
            var decoder = ScaleCodec.decoder(from: Data(hex: hex)!)
            let key = try AnyValueStorageKey(from: &decoder,
                                             base: (name: "ErasStakers", pallet: "Staking"),
                                             runtime: runtime)
            XCTAssertEqual(key.hash.hex(), hex)
        }
    }
    
    func testPlainStorageKey() throws {
        let runtime = try self.runtime()
        let key = PlainKey()
        let prefix = keyPrefix(key: key)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), Data().hex())
        XCTAssertEqual(key.hash.hex(), prefix.hex())
        // Decode
        let decoded = try runtime.decode(from: prefix, PlainKey.self)
        XCTAssertEqual(decoded.hash.hex(), key.hash.hex())
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: Data(repeating: 0, count: prefix.count),
                                                PlainKey.self))
    }
    
    func testFixedMapStructStorageKey() throws {
        let runtime = try self.runtime()
        let value = UInt256(123456) << UInt(140)
        let key = try FixedMapKey(value, runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash = try hashValue(value, runtime: runtime, in: FixedMapKey.TKH.THasher.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), valHash.hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash).hex())
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash, FixedMapKey.self)
        XCTAssertEqual(decoded.hash.hex(), key.hash.hex())
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash.count - 1),
                                                FixedMapKey.self))
        // Iterator
        let iterator = FixedMapKey.TIterator()
        XCTAssertEqual(iterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash)
        let iterDecoded = try iterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(iterDecoded.hash.hex(), key.hash.hex())
    }
    
    func testConcatMapStructStorageKey() throws {
        let runtime = try self.runtime()
        let value = "Some Test String"
        let key = try ConcatMapKey(value, runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash = try hashValue(value, runtime: runtime, in: ConcatMapKey.TKH.THasher.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), valHash.hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash).hex())
        XCTAssertEqual(key.key, value)
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash, ConcatMapKey.self)
        XCTAssertEqual(decoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(decoded.key, key.key)
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0xff, count: valHash.count),
                                                ConcatMapKey.self))
        // Iterator
        let iterator = ConcatMapKey.TIterator()
        XCTAssertEqual(iterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash)
        let iterDecoded = try iterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(iterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(iterDecoded.key, value)
    }
    
    func testFixedMapTupleStorageKey() throws {
        let runtime = try self.runtime()
        let value = UInt256(123456) << UInt(140)
        let key = try TupleKey<Tuple1<FKH<UInt256, HBlake2b512>>>(value, runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash = try hashValue(value, runtime: runtime, in: HBlake2b512.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), valHash.hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash).hex())
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash,
                                         TupleKey<Tuple1<FKH<UInt256, HBlake2b512>>>.self)
        XCTAssertEqual(decoded.hash.hex(), key.hash.hex())
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash.count - 1),
                                                TupleKey<Tuple1<FKH<UInt256, HBlake2b512>>>.self))
        // Iterator
        let iterator = TupleKey<Tuple1<FKH<UInt256, HBlake2b512>>>.TIterator()
        XCTAssertEqual(iterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash)
        let iterDecoded = try iterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(iterDecoded.hash.hex(), key.hash.hex())
    }
    
    func testConcatMapTupleStorageKey() throws {
        let runtime = try self.runtime()
        let value = "Some Test String"
        let key = try TupleKey<Tuple1<CKH<String, HXX64Concat>>>(value, runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash = try hashValue(value, runtime: runtime, in: HXX64Concat.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash, valHash)
        XCTAssertEqual(key.hash, prefix + valHash)
        XCTAssertEqual(key.keys, value)
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash,
                                         TupleKey<Tuple1<CKH<String, HXX64Concat>>>.self)
        XCTAssertEqual(decoded.hash, key.hash)
        XCTAssertEqual(decoded.keys, key.keys)
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0xff, count: valHash.count),
                                                TupleKey<Tuple1<CKH<String, HXX64Concat>>>.self))
        // Iterator
        let iterator = TupleKey<Tuple1<CKH<String, HXX64Concat>>>.TIterator()
        XCTAssertEqual(iterator.hash, prefix)
        var decoder = runtime.decoder(with: prefix + valHash)
        let iterDecoded = try iterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(iterDecoded.hash, key.hash)
        XCTAssertEqual(iterDecoded.keys, value)
    }
    
    func testFixedDoubleMapStructStorageKey() throws {
        let runtime = try self.runtime()
        let value1 = UInt256(123456) << UInt(140)
        let value2 = ["SomeString", "AString"]
        let key = try FixedDMapKey((value1, value2), runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash1 = try hashValue(value1, runtime: runtime, in: FixedDMapKey.TKH1.THasher.self)
        let valHash2 = try hashValue(value2, runtime: runtime, in: FixedDMapKey.TKH2.THasher.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), (valHash1 + valHash2).hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash1 + valHash2).hex())
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash1 + valHash2, FixedDMapKey.self)
        XCTAssertEqual(decoded.hash, key.hash)
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash1.count),
                                                FixedDMapKey.self))
        // DMap Iterator
        let dmapiterator = FixedDMapKey.TIterator()
        XCTAssertEqual(dmapiterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let dmapIterDecoded = try dmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(dmapIterDecoded.hash.hex(), key.hash.hex())
        // Map Iterator
        let mapiterator = try dmapiterator.next(param: value1, runtime: runtime)
        XCTAssertEqual(mapiterator.hash.hex(), (prefix + valHash1).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let mapIterDecoded = try mapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(mapIterDecoded.hash.hex(), key.hash.hex())
    }
    
    func testConcatDoubleMapStructStorageKey() throws {
        let runtime = try self.runtime()
        let value1: [Int32] = [.max, .min]
        let value2 = UInt128(1245) << 80
        let key = try ConcatDMapKey((value1, value2), runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash1 = try hashValue(value1, runtime: runtime, in: ConcatDMapKey.TKH1.THasher.self)
        let valHash2 = try hashValue(value2, runtime: runtime, in: ConcatDMapKey.TKH2.THasher.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), (valHash1 + valHash2).hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash1 + valHash2).hex())
        XCTAssertEqual(TL(key.keys), TL(value1, value2))
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash1 + valHash2, ConcatDMapKey.self)
        XCTAssertEqual(decoded.hash, key.hash)
        XCTAssertEqual(TL(decoded.keys), TL(key.keys))
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0xff,
                                                                    count: valHash1.count + valHash2.count),
                                                ConcatDMapKey.self))
        // DMap Iterator
        let dmapiterator = ConcatDMapKey.TIterator()
        XCTAssertEqual(dmapiterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let dmapIterDecoded = try dmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(dmapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(dmapIterDecoded.keys), TL(key.keys))
        // Map Iterator
        let mapiterator = try dmapiterator.next(param: value1, runtime: runtime)
        XCTAssertEqual(mapiterator.hash.hex(), (prefix + valHash1).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let mapIterDecoded = try mapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(mapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(mapIterDecoded.keys), TL(key.keys))
    }
    
    func testFixedDoubleMapTupleStorageKey() throws {
        let runtime = try self.runtime()
        let value1 = "Some key value"
        let value2 = UInt128(1234) << 80
        let key = try TupleKey<Tuple2<FKH<String, HBlake2b128>, FKH<UInt128, HXX128>>>(
            (value1, value2), runtime: runtime
        )
        let prefix = keyPrefix(key: key)
        let valHash1 = try hashValue(value1, runtime: runtime, in: HBlake2b128.self)
        let valHash2 = try hashValue(value2, runtime: runtime, in: HXX128.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), (valHash1 + valHash2).hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash1 + valHash2).hex())
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash1 + valHash2,
                                         TupleKey<Tuple2<FKH<String, HBlake2b128>, FKH<UInt128, HXX128>>>.self)
        XCTAssertEqual(decoded.hash, key.hash)
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash1.count),
                                                TupleKey<Tuple2<FKH<String, HBlake2b128>, FKH<UInt128, HXX128>>>.self))
        // DMap Iterator
        let dmapiterator = TupleKey<Tuple2<FKH<String, HBlake2b128>, FKH<UInt128, HXX128>>>.TIterator()
        XCTAssertEqual(dmapiterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let dmapIterDecoded = try dmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(dmapIterDecoded.hash.hex(), key.hash.hex())
        // Map Iterator
        let mapiterator = try dmapiterator.next(param: value1, runtime: runtime)
        XCTAssertEqual(mapiterator.hash.hex(), (prefix + valHash1).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let mapIterDecoded = try mapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(mapIterDecoded.hash.hex(), key.hash.hex())
    }
    
    func testConcatDoubleMapTupleStorageKey() throws {
        let runtime = try self.runtime()
        let value1: [Int32] = [.max, .min]
        let value2 = UInt128(1245) << 80
        let key = try TupleKey<Tuple2<CKH<[Int32], HBlake2b128Concat>,
                                      CKH<UInt128, HXX64Concat>>>((value1, value2), runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash1 = try hashValue(value1, runtime: runtime, in: HBlake2b128Concat.self)
        let valHash2 = try hashValue(value2, runtime: runtime, in: HXX64Concat.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), (valHash1 + valHash2).hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash1 + valHash2).hex())
        XCTAssertEqual(TL(key.keys), TL(value1, value2))
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash1 + valHash2,
                                         TupleKey<Tuple2<CKH<[Int32], HBlake2b128Concat>,
                                                         CKH<UInt128, HXX64Concat>>>.self)
        XCTAssertEqual(decoded.hash, key.hash)
        XCTAssertEqual(TL(decoded.keys), TL(key.keys))
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0xff,
                                                                    count: valHash1.count + valHash2.count),
                                                TupleKey<Tuple2<CKH<[Int32], HBlake2b128Concat>,
                                                                CKH<UInt128, HXX64Concat>>>.self))
        // DMap Iterator
        let dmapiterator = TupleKey<Tuple2<CKH<[Int32], HBlake2b128Concat>,
                                           CKH<UInt128, HXX64Concat>>>.self.TIterator()
        XCTAssertEqual(dmapiterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let dmapIterDecoded = try dmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(dmapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(dmapIterDecoded.keys), TL(key.keys))
        // Map Iterator
        let mapiterator = try dmapiterator.next(param: value1, runtime: runtime)
        XCTAssertEqual(mapiterator.hash.hex(), (prefix + valHash1).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2)
        let mapIterDecoded = try mapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(mapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(mapIterDecoded.keys), TL(key.keys))
    }
    
    func testFixedTripleMapTupleStorageKey() throws {
        let runtime = try self.runtime()
        let value1 = "Some key value"
        let value2 = UInt128(1234) << 80
        let value3: [Int64] = [1, 3, .max, .min]
        let key = try TupleKey<Tuple3<FKH<String, HBlake2b128>,
                                      FKH<UInt128, HXX128>,
                                      FKH<[Int64], HBlake2b256>>>(
            (value1, value2, value3), runtime: runtime
        )
        let prefix = keyPrefix(key: key)
        let valHash1 = try hashValue(value1, runtime: runtime, in: HBlake2b128.self)
        let valHash2 = try hashValue(value2, runtime: runtime, in: HXX128.self)
        let valHash3 = try hashValue(value3, runtime: runtime, in: HBlake2b256.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), (valHash1 + valHash2 + valHash3).hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash1 + valHash2 + valHash3).hex())
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash1 + valHash2 + valHash3,
                                         TupleKey<Tuple3<FKH<String, HBlake2b128>,
                                                         FKH<UInt128, HXX128>,
                                                         FKH<[Int64], HBlake2b256>>>.self)
        XCTAssertEqual(decoded.hash, key.hash)
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash1.count),
                                                TupleKey<Tuple3<FKH<String, HBlake2b128>,
                                                                FKH<UInt128, HXX128>,
                                                                FKH<[Int64], HBlake2b256>>>.self))
        // Triple Map Iterator
        let tmapiterator = TupleKey<Tuple3<FKH<String, HBlake2b128>,
                                           FKH<UInt128, HXX128>,
                                           FKH<[Int64], HBlake2b256>>>.TIterator()
        XCTAssertEqual(tmapiterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash1 + valHash2 + valHash3)
        let tmapIterDecoded = try tmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(tmapIterDecoded.hash.hex(), key.hash.hex())
        // Double Map Iterator
        let dmapiterator = try tmapiterator.next(param: value1, runtime: runtime)
        XCTAssertEqual(dmapiterator.hash.hex(), (prefix + valHash1).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2 + valHash3)
        let dmapIterDecoded = try dmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(dmapIterDecoded.hash.hex(), key.hash.hex())
        // Map Iterator
        let mapiterator = try dmapiterator.next(param: value2, runtime: runtime)
        XCTAssertEqual(mapiterator.hash.hex(), (prefix + valHash1 + valHash2).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2 + valHash3)
        let mapIterDecoded = try mapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(mapIterDecoded.hash.hex(), key.hash.hex())
    }
    
    func testConcatTripleMapTupleStorageKey() throws {
        let runtime = try self.runtime()
        let value1 = "Some key value"
        let value2 = UInt128(1234) << 80
        let value3: [Int64] = [1, 3, .max, .min]
        let key = try TupleKey<Tuple3<CKH<String, HIdentity>,
                                      CKH<UInt128, HXX64Concat>,
                                      CKH<[Int64], HBlake2b128Concat>>>(
            (value1, value2, value3), runtime: runtime
        )
        let prefix = keyPrefix(key: key)
        let valHash1 = try hashValue(value1, runtime: runtime, in: HIdentity.self)
        let valHash2 = try hashValue(value2, runtime: runtime, in: HXX64Concat.self)
        let valHash3 = try hashValue(value3, runtime: runtime, in: HBlake2b128Concat.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), (valHash1 + valHash2 + valHash3).hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash1 + valHash2 + valHash3).hex())
        XCTAssertEqual(TL(key.keys), TL(value1, value2, value3))
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash1 + valHash2 + valHash3,
                                         TupleKey<Tuple3<CKH<String, HIdentity>,
                                                         CKH<UInt128, HXX64Concat>,
                                                         CKH<[Int64], HBlake2b128Concat>>>.self)
        XCTAssertEqual(decoded.hash, key.hash)
        XCTAssertEqual(TL(decoded.keys), TL(key.keys))
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash1.count),
                                                TupleKey<Tuple3<CKH<String, HIdentity>,
                                                                CKH<UInt128, HXX64Concat>,
                                                                CKH<[Int64], HBlake2b128Concat>>>.self))
        // Triple Map Iterator
        let tmapiterator = TupleKey<Tuple3<CKH<String, HIdentity>,
                                           CKH<UInt128, HXX64Concat>,
                                           CKH<[Int64], HBlake2b128Concat>>>.TIterator()
        XCTAssertEqual(tmapiterator.hash.hex(), prefix.hex())
        var decoder = runtime.decoder(with: prefix + valHash1 + valHash2 + valHash3)
        let tmapIterDecoded = try tmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(tmapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(tmapIterDecoded.keys), TL(key.keys))
        // Double Map Iterator
        let dmapiterator = try tmapiterator.next(param: value1, runtime: runtime)
        XCTAssertEqual(dmapiterator.hash.hex(), (prefix + valHash1).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2 + valHash3)
        let dmapIterDecoded = try dmapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(dmapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(dmapIterDecoded.keys), TL(key.keys))
        // Map Iterator
        let mapiterator = try dmapiterator.next(param: value2, runtime: runtime)
        XCTAssertEqual(mapiterator.hash.hex(), (prefix + valHash1 + valHash2).hex())
        decoder = runtime.decoder(with: prefix + valHash1 + valHash2 + valHash3)
        let mapIterDecoded = try mapiterator.decode(keyFrom: &decoder, runtime: runtime)
        XCTAssertEqual(mapIterDecoded.hash.hex(), key.hash.hex())
        XCTAssertEqual(TL(mapIterDecoded.keys), TL(key.keys))
    }
    
    struct TupleKey<Path: TupleStorageKeyPath>: TupleStorageKey {
        typealias TPath = Path
        typealias TParams = Path.TKeys.STuple
        typealias TValue = UInt32
        
        static var pallet: String { "Tuple" }
        static var name: String { "Key" }
        
        let path: TPath
        init(path: TPath) { self.path = path }
    }
    
    struct PlainKey: PlainStorageKey {
        typealias TValue = String
        static var pallet: String { "Key" }
        static var name: String { "Plain" }
        init() {}
    }
    
    struct FixedMapKey: MapStorageKey {
        typealias TKH = FKH<UInt256, HXX256>
        typealias TBaseParams = Void
        typealias TParams = TKH.TKey
        typealias TValue = String
        
        let khPair: TKH
        init(khPair: TKH) { self.khPair = khPair }
        
        static var pallet: String { "Key" }
        static var name: String { "FixedMapKey" }
        
    }
    
    struct ConcatMapKey: MapStorageKey {
        typealias TKH = CKH<String, HXX64Concat>
        typealias TBaseParams = Void
        typealias TParams = TKH.TKey
        typealias TValue = UInt256
        
        let khPair: TKH
        init(khPair: TKH) { self.khPair = khPair }
        
        static var pallet: String { "Key" }
        static var name: String { "ConcatMapKey" }
    }
    
    struct FixedDMapKey: DoubleMapStorageKey {
        typealias TKH1 = FKH<UInt256, HXX256>
        typealias TKH2 = FKH<Array<String>, HBlake2b512>
        typealias TBaseParams = Void
        typealias TParams = (TKH1.TKey, TKH2.TKey)
        typealias TValue = String
        
        let khPair1: TKH1
        let khPair2: TKH2
        
        init(khPair1: TKH1, khPair2: TKH2) {
            self.khPair1 = khPair1
            self.khPair2 = khPair2
        }
        
        static var pallet: String { "Key" }
        static var name: String { "FixedDMapKey" }
        
    }
    
    struct ConcatDMapKey: DoubleMapStorageKey {
        typealias TKH1 = CKH<Array<Int32>, HXX64Concat>
        typealias TKH2 = CKH<UInt128, HXX64Concat>
        typealias TBaseParams = Void
        typealias TParams = (TKH1.TKey, TKH2.TKey)
        typealias TValue = Array<String>
        
        let khPair1: TKH1
        let khPair2: TKH2
        
        init(khPair1: TKH1, khPair2: TKH2) {
            self.khPair1 = khPair1
            self.khPair2 = khPair2
        }
        
        static var pallet: String { "Key" }
        static var name: String { "ConcatDMapKey" }
    }
    
    private func runtime() throws -> ExtendedRuntime<DynamicConfig> {
        let data = Resources.inst.metadadav15()
        let opaq = try ScaleCodec.decode(Optional<OpaqueMetadata>.self, from: data)!
        let versioned = try ScaleCodec.decode(VersionedNetworkMetadata.self, from: opaq.raw)
        let metadata = try versioned.metadata.asMetadata()
        return try ExtendedRuntime(config: try DynamicConfig(),
                                   metadata: metadata,
                                   metadataHash: nil,
                                   genesisHash: AnyHash(unchecked: Data()),
                                   version: AnyRuntimeVersion(specVersion: 0,
                                                              transactionVersion: 4,
                                                              other: [:]),
                                   properties: AnySystemProperties(ss58Format: .substrate,
                                                                   other: [:]))
    }

    private func keyPrefix<K: StorageKey>(key: K) -> Data {
        K.prefix(name: key.name, pallet: key.pallet)
    }
    
    private func hashValue<V: RuntimeEncodable, H: StaticHasher>(_ value: V,
                                                                 runtime: Runtime,
                                                                 in type: H.Type) throws -> Data
    {
        return try type.instance.hash(data: runtime.encode(value: value))
    }
}
