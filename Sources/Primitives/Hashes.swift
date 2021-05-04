//
//  Hashes.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol Hash: ScaleFixedData, ScaleDynamicCodable, Codable {}

extension Hash {
    public init(from decoder: Decoder) throws {
        let data = try HexData(from: decoder).data
        guard data.count == Self.fixedBytesCount else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Wrong data size \(data.count), expected \(Self.fixedBytesCount)"
            )
        }
        try self.init(decoding: data)
    }
    
    public func encode(to encoder: Encoder) throws {
        try HexData(encode()).encode(to: encoder)
    }
}

public struct Hash160: Hash {
    let data: Data
    
    public init(_ data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }
    
    public func encode() throws -> Data {
        return self.data
    }

    public static var fixedBytesCount: Int = 20
}

public struct Hash256: Hash {
    let data: Data
    
    public init(_ data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }

    public func encode() throws -> Data {
        return self.data
    }

    public static var fixedBytesCount: Int = 32
}

public struct Hash512: Hash {
    let data: Data
    
    public init(_ data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }

    public func encode() throws -> Data {
        return self.data
    }

    public static var fixedBytesCount: Int = 64
}

public struct SizeMismatchError: Error {
    public let size: Int
    public let expected: Int
    
    public init(size: Int, expected: Int) {
        self.size = size; self.expected = expected
    }
}
