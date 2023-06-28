//
//  BitSequenceTests.swift
//  
//
//  Created by Yehor Popovych on 11.01.2023.
//

import XCTest
import Substrate
import ScaleCodec

final class BitSequenceTests: XCTestCase {
    func testUInt8() {
        let tests: [(BitSequence, [UInt8], [UInt8])] = [
            (BitSequence([true, false, false, true, false]), [9], [144])
        ]
        runEncDec(tests)
    }
    
    func testUInt64() {
        let tests: [(BitSequence, [UInt64], [UInt64])] = [
            (BitSequence([true, false, false, true, false]), [9], [10376293541461622784])
        ]
        runEncDec(tests)
    }
    
    private func runEncDec<U: UnsignedInteger & FixedWidthInteger>(
        _ tests: [(BitSequence, [U], [U])]
    ) {
        for (seq, lsb, msb) in tests {
            XCTAssertEqual(seq.store(order: .lsb0), lsb)
            XCTAssertEqual(seq.store(order: .msb0), msb)
            XCTAssertEqual(seq, BitSequence(count: seq.count, storage: lsb, order: .lsb0))
            XCTAssertEqual(seq, BitSequence(count: seq.count, storage: msb, order: .msb0))
        }
        
    }
}
