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
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9007cbc1270b5b091758f9c42f5915b3e8ac59e11963af19174d0b94d5d78041c233f55d2e19324665bafdfb62925af2d",
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da94f9aea1afa791265fae359272badc1cf8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48",
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da98578796c363c105114787203e4d93ca6101191192fc877c24d725b337120fa3edc63d227bbc92705db1e2cb65f56981a",
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da923a05cabf6d3bde7ca3ef0d11596b5611cbd2d43530a44705ad088af313e18f80b53ef16b36177cd4b77b846f2a5f07c",
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da96f2e33376834a63c86a195bcf685aebbfe65717dad0447d715f660a0a58411de509b42e6efb8375f562f58a554d5860e",
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9f3f619a1c2956443880db9cc9a13d058e860f1b1c7227f7c22602f53f15af80747814dffd839719731ee3bba6edc126c",
            "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9e5e802737cce3a54b0bc9e3d3e6be26e306721211d5404bd9da88e0204360a1a9ab8b87c66c1bc2fcdd37f3c2222cc20"
        ]
        
        let runtime = try self.runtime()
        
        for hex in keys {
            var decoder = ScaleCodec.decoder(from: Data(hex: hex)!)
            let key = try AnyValueStorageKey(from: &decoder,
                                             base: (name: "Account", pallet: "System"),
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
        let key = try TupleKey<Tuple1<FKH<UInt256, HBlake2b256>>>(value, runtime: runtime)
        let prefix = keyPrefix(key: key)
        let valHash = try hashValue(value, runtime: runtime, in: HBlake2b256.self)
        // Encode
        XCTAssertEqual(key.prefix.hex(), prefix.hex())
        XCTAssertEqual(key.pathHash.hex(), valHash.hex())
        XCTAssertEqual(key.hash.hex(), (prefix + valHash).hex())
        // Decode
        let decoded = try runtime.decode(from: prefix + valHash,
                                         TupleKey<Tuple1<FKH<UInt256, HBlake2b256>>>.self)
        XCTAssertEqual(decoded.hash.hex(), key.hash.hex())
        // Decode fail
        XCTAssertThrowsError(try runtime.decode(from: prefix + Data(repeating: 0, count: valHash.count - 1),
                                                TupleKey<Tuple1<FKH<UInt256, HBlake2b256>>>.self))
        // Iterator
        let iterator = TupleKey<Tuple1<FKH<UInt256, HBlake2b256>>>.TIterator()
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
    
    struct TupleKey<Path: TupleStorageIdentifiableKeyPath>: TupleStorageKey, IdentifiableFrameType {
        typealias TPath = Path
        typealias TParams = Path.TKeys.STuple
        typealias TValue = UInt32
        
        static var pallet: String { "Tuple" }
        static var name: String { "Key" }
        
        let path: TPath
        init(path: TPath) { self.path = path }
    }
    
    struct PlainKey: PlainStorageKey, IdentifiableFrameType {
        typealias TValue = String
        static var pallet: String { "Key" }
        static var name: String { "Plain" }
        init() {}
    }
    
    struct FixedMapKey: MapStorageKey, IdentifiableFrameType {
        typealias TKH = FKH<UInt256, HXX256>
        typealias TBaseParams = Void
        typealias TypeInfo = StorageKeyTypeInfo
        typealias TParams = TKH.TKey
        typealias TValue = String
        
        let khPair: TKH
        init(khPair: TKH) { self.khPair = khPair }
        
        static var pallet: String { "Key" }
        static var name: String { "FixedMapKey" }
        
    }
    
    struct ConcatMapKey: MapStorageKey, IdentifiableFrameType {
        typealias TypeInfo = StorageKeyTypeInfo
        typealias TKH = CKH<String, HXX64Concat>
        typealias TBaseParams = Void
        typealias TParams = TKH.TKey
        typealias TValue = UInt256
        
        let khPair: TKH
        init(khPair: TKH) { self.khPair = khPair }
        
        static var pallet: String { "Key" }
        static var name: String { "ConcatMapKey" }
    }
    
    struct FixedDMapKey: DoubleMapStorageKey, IdentifiableFrameType {
        typealias TKH1 = FKH<UInt256, HXX256>
        typealias TKH2 = FKH<Array<String>, HBlake2b256>
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
    
    struct ConcatDMapKey: DoubleMapStorageKey, IdentifiableFrameType {
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
    
    private func runtime() throws -> ExtendedRuntime<Configs.Dynamic<AccountId32, HBlake2b256>> {
        let data = Resources.inst.metadadav15()
        let opaq = try ScaleCodec.decode(Optional<OpaqueMetadata>.self, from: data)!
        let versioned = try ScaleCodec.decode(VersionedNetworkMetadata.self, from: opaq.raw)
        let config = Configs.Registry.dynamicBlake2.config
        let metadata = try versioned.metadata.asMetadata()
        let types = try config.dynamicTypes(metadata: metadata)
        return try ExtendedRuntime(config: config,
                                   metadata: metadata, types: types,
                                   metadataHash: nil,
                                   genesisHash: Hash256(decoding: Data(repeating: 0, count: 32)),
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
