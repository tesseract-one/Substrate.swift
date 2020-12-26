//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import XCTest
import ScaleCodec

extension Data {
    init?(hex: String) {
        guard let hexData = hex.data(using: .ascii) else {
            return nil
        }
        let prefix = hex.hasPrefix("0x") ? 2 : 0
        let result: Data? = hexData.withUnsafeBytes() { hex in
            var result = Data()
            result.reserveCapacity((hexData.count - prefix) / 2)
            var current: UInt8? = nil
            for indx in prefix ..< hex.count {
                let v: UInt8
                switch hex[indx] {
                case let c where c <= 57: v = c - 48
                case let c where c >= 65 && c <= 70: v = c - 55
                case let c where c >= 97: v = c - 87
                default: return nil
                }
                if let val = current {
                    result.append(val << 4 | v)
                    current = nil
                } else {
                    current = v
                }
            }
            return result
        }
        guard let data = result else {
            return nil
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
}
