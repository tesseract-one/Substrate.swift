//
//  PublicKey.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//

import Foundation
import ScaleCodec

public protocol PublicKey: ScaleCodable, Hashable {
    init(bytes: Data) throws
    var bytes: Data { get }
    var typeId: CryptoTypeId { get }
    
    static var bytesCount: Int { get }
}

extension PublicKey {
    public static func from(ss58: String) throws -> (key: Self, format: Ss58AddressFormat) {
        let (data, format) = try Ss58AddressCodec.instance.decode(string: ss58)
        return try (Self(bytes: data), format)
    }
    
    public func ss58(format: Ss58AddressFormat) -> String {
        Ss58AddressCodec.instance.encode(data: bytes, format: format)
    }
}

public struct Ed25519PublicKey: PublicKey, ScaleFixedData {
    public let bytes: Data
    
    public init(bytes: Data) throws {
        guard bytes.count == Self.bytesCount else {
            throw SizeMismatchError(size: bytes.count, expected: Self.bytesCount)
        }
        self.bytes = bytes
    }
    
    public init(decoding data: Data) throws {
        try self.init(bytes: data)
    }
    
    public func encode() throws -> Data { bytes }
    
    public var typeId: CryptoTypeId { .ed25519 }
    public static var fixedBytesCount: Int = Self.bytesCount
    public static var bytesCount: Int = 32
}

public struct Sr25519PublicKey: PublicKey, ScaleFixedData {
    public let bytes: Data
    
    public init(bytes: Data) throws {
        guard bytes.count == Self.bytesCount else {
            throw SizeMismatchError(size: bytes.count, expected: Self.bytesCount)
        }
        self.bytes = bytes
    }
    
    public init(decoding data: Data) throws {
        try self.init(bytes: data)
    }
    
    public func encode() throws -> Data { bytes }
    
    public var typeId: CryptoTypeId { .sr25519 }
    public static var fixedBytesCount: Int = Self.bytesCount
    public static var bytesCount: Int = 32
}

public struct EcdsaPublicKey: PublicKey, ScaleFixedData {
    public let bytes: Data
    
    public init(bytes: Data) throws {
        guard bytes.count == Self.bytesCount else {
            throw SizeMismatchError(size: bytes.count, expected: Self.bytesCount)
        }
        self.bytes = bytes
    }
    
    public init(decoding data: Data) throws {
        try self.init(bytes: data)
    }
    
    public func encode() throws -> Data { bytes }
    
    public var typeId: CryptoTypeId { .ecdsa }
    public static var fixedBytesCount: Int = Self.bytesCount
    public static var bytesCount: Int = 33
}
