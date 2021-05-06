//
//  HashersTests.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import XCTest

#if !COCOAPODS
import SubstratePrimitives
#else
import Substrate
#endif

final class HashersTests: XCTestCase {
    func testBlake2b128() {
        let hashed = HBlake2b128.hasher.hash(data: "abc".utf8)
        XCTAssertEqual(hashed.hex, "cf 4a b7 91 c6 2b 8d 2b 21 09 c9 02 75 28 78 16")
    }
    
    func testBlake2b256() {
        let hashed = HBlake2b256.hasher.hash(data: "aba".utf8)
        let expected = "a4 51 4e 24 9d 82 d2 7d 40 a7 cb 1b 49 e5 02 2d 48 d0 "
            + "2d 4e ff 20 24 78 dc ed a9 33 28 75 88 2e"
        XCTAssertEqual(hashed.hex, expected)
    }
    
    func testBlake2b512() {
        let hashed = HBlake2b512.hasher.hash(data: "abc".utf8)
        let expected = "ba 80 a5 3f 98 1c 4d 0d 6a 27 97 b6 9f 12 f6 e9 4c 21 2f 14 "
            + "68 5a c4 b7 4b 12 bb 6f db ff a2 d1 7d 87 c5 39 2a ab 79 2d c2 52 d5 "
            + "de 45 33 cc 95 18 d3 8a a8 db f1 92 5a b9 23 86 ed d4 00 99 23"
        XCTAssertEqual(hashed.hex, expected)
    }
    
    func testBlake2b128Concat() {
        let data = "abc".utf8
        let hashed = HBlake2b128Concat.hasher.hash(data: data)
        XCTAssertEqual(hashed.hex, "cf 4a b7 91 c6 2b 8d 2b 21 09 c9 02 75 28 78 16 \(data.hex)")
    }
}
