//
//  Helpers.swift
//  
//
//  Created by Yehor Popovych on 10/1/20.
//

import XCTest
import ScaleCodec

extension Data {
    init?(hex: String) {
        let hexString = hex.replacingOccurrences(of: " ", with: "").dropFirst(hex.hasPrefix("0x") ? 2 : 0)
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    var hex: String {
        self.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}

extension String {
    var hexData: Data? {
        return Data(hex: self)
    }
    
    var utf8: Data {
        return data(using: .utf8)!
    }
}

func RunEncDecTests<T: Equatable & ScaleCodable>(_ tests: [(T, String)]) {
    let codec = SCALE.default
    
    for (v, d) in tests {
        do {
            let data = try codec.encode(v)
            let decoded = try codec.decode(T.self, from: d.hexData!)
            XCTAssertEqual(data.hex, d)
            XCTAssertEqual(decoded, v)
        } catch {
            XCTFail("\(error)")
        }
    }
}
