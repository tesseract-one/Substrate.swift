//
//  HelperProtocols.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec

public protocol BlockNumberProtocol: ScaleDynamicCodable, SDefault, Codable {
    static var firstBlock: Self { get }
}

extension UnsignedInteger {
    public static var firstBlock: Self { 0 }
}

//extension ScaleFixedUnsignedInteger {
//    public static var firstBlock: Self { 0 }
//}

extension UInt32: BlockNumberProtocol {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard data.count == Self.fixedBytesCount else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Wrong data size \(data.count), expected \(Self.fixedBytesCount)"
            )
        }
        try self.init(decoding: data)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encode())
    }
}

extension UInt64: BlockNumberProtocol {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard data.count == Self.fixedBytesCount else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Wrong data size \(data.count), expected \(Self.fixedBytesCount)"
            )
        }
        try self.init(decoding: data)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encode())
    }
}

//extension SUInt128: BlockNumberProtocol {}
//extension SUInt256: BlockNumberProtocol {}
//extension SUInt512: BlockNumberProtocol {}
