//
//  Hashes.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol Hash: Codable, ValueConvertible {
    var data: Data { get }
    init(_ data: Data) throws
}

public protocol StaticHash: Hash, ScaleFixedData {}

extension Hash {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
    
    public init<C>(value: Value<C>) throws {
         switch value.value {
         case .primitive(.bytes(let data)):
             try self.init(data)
         case .sequence(let vals):
             try self.init(Data(vals.map { try UInt8(value: $0) }))
         default:
             throw ValueInitializableError<C>.wrongValueType(got: value.value,
                                                             for: String(describing: Self.self))
         }
     }
     
     public func asValue() throws -> Value<Void> {
         .bytes(data)
     }
}

extension StaticHash {
    public init(decoding data: Data) throws {
        try self.init(data)
    }
    
    public func serialize() -> Data {
        self.data
    }
}

public struct Hash128: StaticHash {
    public let data: Data
    
    public init(_ data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
    }
    
    public static var fixedBytesCount: Int = 16
}

public struct Hash160: StaticHash {
    public let data: Data
    
    public init(_ data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        self.data = data
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
    
    public static var fixedBytesCount: Int = 64
}

public struct DynamicHash: Hash {
    public let data: Data
    
    public init(_ data: Data) throws {
        self.data = data
    }
}

public struct SizeMismatchError: Error {
    public let size: Int
    public let expected: Int
    
    public init(size: Int, expected: Int) {
        self.size = size; self.expected = expected
    }
}
