//
//  StorageKeyTests.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import XCTest
import Primitives
import ScaleCodec

final class StorageKeyTests: XCTestCase {
    
    func testDoubleMapEncodind() {
//        let key = StorageKeyDoubleMap<HIdentity, HIdentity, UInt16, UInt32>(module: "Sudo", field: "Key", path: (255, 123456))
//        let data = try! SCALE.default.encode(key)
//        let key2: StorageKeyDoubleMap<HIdentity, HIdentity, UInt16, UInt32> = try! SCALE.default.decode(from: data)
//        let path = key2.key.path
//        print("\(data as NSData)", path)
    }
}

//private struct DoubleMapKey: StorageKey {
//    typealias KeyType = StorageKeyTypeDoubleMap<HasherIdentity, HasherIdentity, UInt16, UInt32>
//
//    let prefix: Data
//    let key: KeyType
//
//    init(prefix: Data, key: KeyType) {
//        self.prefix = prefix; self.key = key
//    }
//}
