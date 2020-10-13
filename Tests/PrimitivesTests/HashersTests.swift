//
//  HashersTests.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import XCTest
import Primitives

final class HashersTests: XCTestCase {
    func testBlake2b128() {
        let hashed = HBlake2b128.hasher.hash(data: "abc".utf8)
        XCTAssertEqual(hashed.hex, "cf 4a b7 91 c6 2b 8d 2b 21 09 c9 02 75 28 78 16")
    }
    
    func testBlake2b128Concat() {
        let data = "abc".utf8
        let hashed = HBlake2b128Concat.hasher.hash(data: data)
        XCTAssertEqual(hashed.hex, "cf 4a b7 91 c6 2b 8d 2b 21 09 c9 02 75 28 78 16 \(data.hex)")
    }
}
