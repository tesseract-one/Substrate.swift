//
//  CodableExtensions.swift
//  
//
//  Created by Yehor Popovych on 13.04.2023.
//

import Foundation
import Serializable
import ScaleCodec

extension Compact: Decodable where T.UI: DataInitalizable {
    public init(from decoder: Decoder) throws {
        let uint = try UIntHex<T.UI>(from: decoder)
        self.init(T(uint: uint.value))
    }
}

extension Compact: Encodable where T.UI: DataSerializable {
    public func encode(to encoder: Encoder) throws {
        try UIntHex(value.uint).encode(to: encoder)
    }
}

extension DoubleWidth: Codable where Base: UnsignedInteger {
    public init(from decoder: Decoder) throws {
        self = try UIntHex<Self>(from: decoder).value
    }
    
    public func encode(to encoder: Encoder) throws {
        try UIntHex(self).encode(to: encoder)
    }
}
