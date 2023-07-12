//
//  Hashes.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol Hash: Swift.Codable, ValueRepresentable, VoidValueRepresentable, Equatable {
    var data: Data { get }
    init(_ data: Data) throws
}

public protocol StaticHash: Hash, FixedDataCodable {}

extension Hash {
    public init(from decoder: Swift.Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(data)
    }
    
    public func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
    
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let count = info.asBytes(metadata: runtime.metadata) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        guard count == 0 || data.count == count else {
            throw ValueRepresentableError.wrongValuesCount(in: info, expected: data.count,
                                                           for: String(describing: Self.self))
        }
        return .bytes(data, type)
    }
     
     public func asValue() -> Value<Void> {
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

public struct AnyHash: Hash {
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
