//
//  AccountIndex.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountIndex: Equatable, Hashable {
    public let value: UInt64
    
    public init(_ value: UInt64) {
        self.value = value
    }
}

extension AccountIndex: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let byte: UInt8 = try decoder.decode()
        switch byte {
        case 0...0xef: value = UInt64(byte)
        case 0xfc: value = try UInt64(decoder.decode(UInt16.self))
        case 0xfd: value = try UInt64(decoder.decode(UInt32.self))
        case 0xfe: value = try decoder.decode()
        default:
            throw SDecodingError.dataCorrupted(SDecodingError.Context(
                path: decoder.path,
                description: "Invalid AccountIndex variant: \(byte)"
            ))
        }
    }
       
    public func encode(in encoder: ScaleEncoder) throws {
        var marker: UInt8
        var encode: ScaleEncodable?
        switch value {
        case 0...0xef:
            marker = UInt8(value)
            encode = nil
        case 0xf0...UInt64(UInt16.max):
            marker = 0xfc
            encode = UInt16(value)
        case UInt64(UInt16.max)+1...UInt64(UInt32.max):
            marker = 0xfd
            encode = UInt32(value)
        default:
            marker = 0xfe
            encode = value
        }
        encoder.write(Data(repeating: marker, count: 1))
        if let val = encode {
            try encoder.encode(val)
        }
    }
}

extension AccountIndex: ScaleDynamicCodable {}
