//
//  PublicKeys.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct Ed25519PublicKey: PublicKey, FixedDataCodable, Default {
    public let raw: Data
    
    public init(_ raw: Data) throws {
        try self.init(decoding: raw)
    }
    
    public init(decoding raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public func serialize() -> Data { raw }
    
    public var algorithm: CryptoTypeId { .ed25519 }
    public static var fixedBytesCount: Int = 32
    public static var `default`: Self = try! Self(Data(repeating: 0, count: Self.fixedBytesCount))
}

public struct Sr25519PublicKey: PublicKey, FixedDataCodable, Default {
    public let raw: Data
    
    public init(_ raw: Data) throws {
        try self.init(decoding: raw)
    }
    
    public init(decoding raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public func serialize() -> Data { raw }
    
    public var algorithm: CryptoTypeId { .sr25519 }
    public static var fixedBytesCount: Int = 32
    public static var `default`: Self = try! Self(Data(repeating: 0, count: Self.fixedBytesCount))
}

public struct EcdsaPublicKey: PublicKey, FixedDataCodable, Default {
    public let raw: Data
    
    public init(_ raw: Data) throws {
        try self.init(decoding: raw)
    }
    
    public init(decoding raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public func serialize() -> Data { raw }
    
    public var algorithm: CryptoTypeId { .ecdsa }
    public static var fixedBytesCount: Int = 33
    public static var `default`: Self = try! Self(Data(repeating: 0, count: Self.fixedBytesCount))
}
