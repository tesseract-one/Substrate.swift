//
//  Hashes.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol Hash: Codable {
    var data: Data { get }
    init(_ data: Data) throws
}

public protocol StaticHash: Hash, ScaleFixedData, RegistryScaleCodable {}

extension StaticHash {
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
        try container.encode(serialize())
    }
}

public struct DynamicHash: Hash {
    public let data: Data
    
    public init(data: Data) {
        self.data = data
    }
    
    public init(_ data: Data) throws {
        self.init(data: data)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self.init(data: data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

public struct Hash160: StaticHash {
    public let data: Data
    
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
    
    public func serialize() -> Data {
        return self.data
    }

    public static var fixedBytesCount: Int = 20
}

public struct Hash256: StaticHash {
    public let data: Data
    
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

    public func serialize() -> Data {
        return self.data
    }

    public static var fixedBytesCount: Int = 32
}

public struct Hash512: StaticHash {
    public let data: Data
    
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

    public func serialize() -> Data {
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
