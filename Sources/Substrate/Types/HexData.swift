//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/27/20.
//

import Foundation

public struct HexData: Codable {
    public let data: Data
    
    public init<D: DataProtocol>(_ data: D) {
        self.data = Data(data)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let data = Self.fromHex(hex: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Can't decode hex string: \(string)"
            )
        }
        self.data = data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Self.toHex(data: data))
    }
    
    public static func fromHex(hex: String) -> Data? {
        guard let hexData = hex.data(using: .ascii) else { return nil }
        let prefix = hex.hasPrefix("0x") ? 2 : 0
        return hexData.withUnsafeBytes { hex in
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
    }
    
    public static func toHex(data: Data, prefix: Bool = true) -> String {
        return data.withUnsafeBytes { data in
            var result = Data()
            result.reserveCapacity(data.count * 2 + (prefix ? 2 : 0))
            if prefix {
                result.append(UInt8(ascii: "0"))
                result.append(UInt8(ascii: "x"))
            }
            Self._hexCharacters.withUnsafeBytes { hex in
                for byte in data {
                    result.append(hex[Int(byte >> 4)])
                    result.append(hex[Int(byte & 0x0F)])
                }
            }
            return String(bytes: result, encoding: .ascii)!
        }
    }
    
    private static let _hexCharacters = Data(
        [UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
         UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
         UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "a"), UInt8(ascii: "b"),
         UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f")]
    )
}
