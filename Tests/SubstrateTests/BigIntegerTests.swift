//
//  BigIntegerTests.swift
//  
//
//  Created by Yehor Popovych on 11/08/2023.
//

import XCTest
import ScaleCodec
@testable import Substrate
import NBKCoreKit

final class BigIntegerTests: XCTestCase {
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    func testCompact128() {
        runCompactTests(compactValues(for: UInt128.self))
    }
    
    func testCompact256() {
        runCompactTests(compactValues(for: UInt256.self))
    }
    
    func testCompact512() {
        runCompactTests(compactValues(for: UInt512.self))
    }
        
    func testCompact1024() {
        runCompactTests(compactValues(for: UInt1024.self))
        XCTAssertThrowsError(try ScaleCodec.encode(UInt1024(1) << 536, .compact))
    }
    
    func testInt128() {
        let tests = intValues(
            max: Int128.max,
            min: Int128.min,
            bytes: Int128.bitWidth / 8
        )
        runEncDecTests(tests)
    }
        
    func testUInt128() {
        let tests = uintValues(
            max: UInt128.max,
            bytes: UInt128.bitWidth / 8
        )
        runEncDecTests(tests)
        runJsonEncDecTests(jsonValues(for: UInt128.self))
    }
        
    func testInt256() {
        let tests = intValues(
            max: Int256.max,
            min: Int256.min,
            bytes: Int256.bitWidth / 8
        )
        runEncDecTests(tests)
    }
        
    func testUInt256() {
        let tests = uintValues(
            max: UInt256.max,
            bytes: UInt256.bitWidth / 8
        )
        runEncDecTests(tests)
        runJsonEncDecTests(jsonValues(for: UInt256.self))
    }
        
    func testInt512() {
        let tests = intValues(
            max: Int512.max,
            min: Int512.min,
            bytes: Int512.bitWidth / 8
        )
        runEncDecTests(tests)
    }
        
    func testUInt512() {
        let tests = uintValues(
            max: UInt512.max,
            bytes: UInt512.bitWidth / 8
        )
        runEncDecTests(tests)
        runJsonEncDecTests(jsonValues(for: UInt512.self))
    }
    
    func testInt1024() {
        let tests = intValues(
            max: Int1024.max,
            min: Int1024.min,
            bytes: Int1024.bitWidth / 8
        )
        runEncDecTests(tests)
    }
        
    func testUInt1024() {
        let tests = uintValues(
            max: UInt1024.max,
            bytes: UInt1024.bitWidth / 8
        )
        runEncDecTests(tests)
        runJsonEncDecTests(jsonValues(for: UInt1024.self))
    }
        
    private func uintValues<T: UnsignedInteger>(max: T, bytes: Int) -> [(T, String)] {
        let z = Data(repeating: 0x00, count: bytes)
        let m = Data(repeating: 0xff, count: bytes)
        let h = Data(repeating: 0x00, count: bytes - 1) + Data([0x80])
        let p1 = Data([0x01]) + Data(repeating: 0x00, count: bytes - 1)
        return [(T(0), z.hex(prefix: false)),
                (T(1), p1.hex(prefix: false)),
                (max/2+1, h.hex(prefix: false)),
                (max, m.hex(prefix: false))]
    }
            
    private func intValues<T: SignedInteger>(max: T, min: T, bytes: Int) -> [(T, String)] {
        let mn = Data(repeating: 0x00, count: bytes - 1) + Data([0x80])
        let mx = Data(repeating: 0xff, count: bytes - 1) + Data([0x7f])
        let z = Data(repeating: 0x00, count: bytes)
        let m1 = Data(repeating: 0xff, count: bytes)
        let p1 = Data([0x01]) + Data(repeating: 0x00, count: bytes - 1)
        return [(min, mn.hex(prefix: false)),
                (T(-1), m1.hex(prefix: false)),
                (T(0), z.hex(prefix: false)),
                (T(1), p1.hex(prefix: false)),
                (max, mx.hex(prefix: false))]
    }
    
    private func compactValues<T>(for: T.Type) -> [(T, String)]
        where T: UnsignedInteger & NBKFixedWidthInteger & CompactCodable & DataSerializable, T.UI == T
    {
        var values: [(T, String)] = [
            (T(0), "00"), (T(1 << 6 - 1), "fc"), (T(1 << 6), "01 01"),
            (T(UInt8.max), "fd 03"), (T(1 << 14 - 1), "fd ff"), (T(1 << 14), "02 00 01 00"),
            (T(UInt16.max), "fe ff 03 00"), (T(1 << 30 - 1), "fe ff ff ff"),
            (T(1 << 30), "03 00 00 00 40"),
        ]
        let pair = { (val: T) -> (T, String) in
            var bytes = val.trimmedLittleEndianData
            bytes.insert((UInt8(bytes.count) - 4) << 2 + 0b11, at: 0)
            return (val, bytes.hex(prefix: false))
        }
        values.reserveCapacity(values.count + (((T.compactBitWidth - UInt32.bitWidth) / 8 + 1) * 2))
        for shft in stride(from: UInt32.bitWidth, to: T.compactBitWidth - 8, by: 8) {
            values.append(pair(T(1) << UInt(shft)))
            values.append(pair(T(1) << UInt(shft + 8) - 1))
        }
        values.append(pair(T.compactMax))
        return values
    }
    
    private func jsonValues<T>(for: T.Type) -> [(T, String)]
        where T: UnsignedInteger & NBKFixedWidthInteger & DataSerializable
    {
        var values: [(T, String)] = []
        values.reserveCapacity(((T.bitWidth / 8) + 3) * 2)
        let pair = { (val: T) -> (T, String) in
            if val <= JSONEncoder.maxSafeInteger {
                return (val, val.description(radix: 10, uppercase: false))
            } else {
                let hex = TrimmedHex(data: val.data(littleEndian: false, trimmed: true))
                return (val, "\"\(hex.string)\"")
            }
        }
        values.append(pair(0))
        for shft in stride(from: 0, to: T.bitWidth - 8, by: 8) {
            values.append(pair(T(1) << UInt(shft)))
            values.append(pair(T(1) << UInt(shft + 8) - 1))
        }
        values.append(pair(T.max))
        values.append(pair(T(JSONEncoder.maxSafeInteger)))
        values.append(pair(T(JSONEncoder.maxSafeInteger + 1)))
        return values
    }
    
    private func runCompactTests<T: CompactCodable & Equatable>(_ tests: [(T, String)]) {
        let ctests = tests.map { (v, d) in
            return (Compact(v), d)
        }
        runEncDecTests(ctests)
    }
    
    private func runEncDecTests<T: Equatable & Codable>(_ tests: [(T, String)]) {
        for (v, d) in tests {
            do {
                let hex = d.replacingOccurrences(of: " ", with: "")
                let data = try ScaleCodec.encode(v)
                let decoded = try ScaleCodec.decode(T.self, from: Data(hex: hex)!)
                XCTAssertEqual(data.hex(prefix: false), hex)
                XCTAssertEqual(decoded, v)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    private func runJsonEncDecTests<T: Equatable & Swift.Codable>(_ tests: [(T, String)]) {
        for (v, s) in tests {
            do {
                let encoded = String(data: try jsonEncoder.encode(v), encoding: .utf8)!
                let decoded = try jsonDecoder.decode(T.self, from: Data(s.utf8))
                XCTAssertEqual(encoded, s)
                XCTAssertEqual(decoded, v)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
}
