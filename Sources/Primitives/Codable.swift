//
//  Codable.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation
import ScaleCodec

public protocol BigFixedUIntCodable: Codable, ScaleFixedUnsignedInteger where UI == BigUInt {}

extension BigFixedUIntCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if string == "0x0" {
            try self.init(bigUInt: BigUInt(0))
        } else {
            guard var data = Data(hex: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Bad hexvalue"
                )
            }
            let zeroes = (Self.bitWidth / 8) - data.count
            if zeroes > 0 {
                data = Data(repeating: 0, count: zeroes) + data
            }
            try self.init(bigUInt: BigUInt(data))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = self.int.serialize()
        let nonZero = data.firstIndex { $0 != 0 }
        if data.count == 0 {
            try container.encode("0x0")
        } else {
            let trimmed = nonZero != nil ? data.suffix(from: nonZero!) : data
            try container.encode(trimmed.hex(prefix: true))
        }
    }
}

extension SUInt128: BigFixedUIntCodable {}
extension SUInt256: BigFixedUIntCodable {}
extension SUInt512: BigFixedUIntCodable {}

public struct CodableComplexKey<T: Equatable>: CodingKey, Equatable {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }

    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
