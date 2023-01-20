//
//  UInt+HexCodable.swift
//  
//
//  Created by Yehor Popovych on 06.01.2023.
//

import Foundation
import ScaleCodec

private let maxJsonSafeInteger: UInt64 = 2^53 - 1

public struct UIntHex<T: UnsignedInteger> {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}

extension UIntHex: Decodable where T: DataInitalizable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        var string = try container.decode(String.self)
        if string == "0x0" {
            self.init(0)
        } else {
            if string.hasPrefix("0x") {
                string.removeFirst(2)
            }
            if string.count % 2 == 1 {
                string.insert("0", at: string.startIndex)
            }
            guard let data = Data(hex: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Bad hex value \(string)"
                )
            }
            guard let val = T(data: data, littleEndian: false, trimmed: true) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Can't initialize \(T.self) from \(string)"
                )
            }
            self.init(val)
        }
    }
}

extension UIntHex: Encodable where T: DataSerializable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value == 0 {
            try container.encode("0x0")
        } else {
            var hex = value.data(littleEndian: false, trimmed: true).hex(prefix: false)
            if (hex[hex.startIndex] == "0") {
                hex.remove(at: hex.startIndex)
            }
            hex.insert(contentsOf: "0x", at: hex.startIndex)
            try container.encode(hex)
        }
    }
}

public struct HexOrNumber<T: UnsignedInteger> {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}

extension HexOrNumber: Decodable where T: Decodable & DataInitalizable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(T.self) {
            self.init(value)
        } else {
            self.init(try container.decode(UIntHex<T>.self).value)
        }
    }
}

extension HexOrNumber: Encodable where T: Encodable & DataSerializable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if UInt64(clamping: value) > maxJsonSafeInteger {
            try container.encode(UIntHex(value))
        } else {
            try container.encode(value)
        }
    }
}
