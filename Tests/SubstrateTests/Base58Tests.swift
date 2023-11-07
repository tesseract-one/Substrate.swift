//
//  Base58Tests.swift
//  
//
//  Created by Yehor Popovych on 07/11/2023.
//

import XCTest
import ScaleCodec
@testable import Substrate

final class Base58Tests: XCTestCase {
    func testEncDec() throws {
        try encDec(Data(hex: "6c13537af75e5a3b724db7334798f9084c192a2896e0c68a4216151b8e29bb32435f")!)
    }
    
    func testEncDecZeroes() throws {
        try encDec(Data(hex: "006c13537af75e5a3b724db7334798f9084c192a2896e0c68a4216151b8e29bb32435f")!)
        try encDec(Data(hex: "00006c13537af75e5a3b724db7334798f9084c192a2896e0c68a4216151b8e29bb32435f")!)
        try encDec(Data(hex: "0000006c13537af75e5a3b724db7334798f9084c192a2896e0c68a4216151b8e29bb32435f")!)
        try encDec(Data(hex: "000000006c13537af75e5a3b724db7334798f9084c192a2896e0c68a4216151b8e29bb32435f")!)
    }
    
    private func encDec(_ data: Data) throws {
        let encoded = Base58.encode(data)
        let decoded = try Base58.decode(encoded)
        XCTAssertEqual(data.hex(), decoded.hex())
    }
}
