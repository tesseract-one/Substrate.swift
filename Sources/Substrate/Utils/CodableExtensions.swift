//
//  CodableExtensions.swift
//  
//
//  Created by Yehor Popovych on 13.04.2023.
//

import Foundation
import Serializable
import ScaleCodec

extension Compact: Decodable where T.UI: DataInitalizable & Decodable {
    public init(from decoder: Decoder) throws {
        let uint = try HexOrNumber<T.UI>(from: decoder)
        self.init(T(uint: uint.value))
    }
}

extension Compact: Encodable where T.UI: DataSerializable & Encodable {
    public func encode(to encoder: Encoder) throws {
        try HexOrNumber(value.uint).encode(to: encoder)
    }
}

extension DoubleWidth: Codable where Base: UnsignedInteger {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(UInt64.self) {
            self.init(value)
        } else {
            self.init(try container.decode(UIntHex<Self>.self).value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if UInt64(clamping: self) > JSONEncoder.maxSafeInteger {
            try container.encode(UIntHex(self))
        } else {
            try container.encode(UInt64(self))
        }
    }
}
