//
//  PublicKey.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//

import Foundation
import ScaleCodec

public protocol Ss58CodableKey {
    static func from(ss58: String) throws -> Self
    var ss58: String { get }
}

public protocol PublicKey: ScaleDynamicCodable, Ss58CodableKey {
    init(bytes: Data, format: Ss58AddressFormat) throws
    
    var bytes: Data { get }
    var format: Ss58AddressFormat { get }
    var typeId: CryptoTypeId { get }
    
    static var typeId: CryptoTypeId { get }
    static var bytesCount: Int { get }
}

extension PublicKey {
    public static func from(ss58: String) throws -> Self {
        let (data, format) = try Ss58AddressCodec.instance.decode(string: ss58)
        return try Self(bytes: data, format: format)
    }
    
    public var ss58: String {
        Ss58AddressCodec.instance.encode(data: bytes, format: format)
    }
    
    public var typeId: CryptoTypeId { Self.typeId }
    
    public static func `default`() -> Self {
        return try! Self(bytes: Data(repeating: 0, count: Self.bytesCount), format: .substrate)
    }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let data: Data = try decoder.decode(.fixed(UInt(Self.bytesCount)))
        try self.init(bytes: data, format: registry.ss58AddressFormat)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encoder.encode(bytes, .fixed(UInt(Self.bytesCount)))
    }
}

public struct Ed25519PublicKey: PublicKey, Hashable, SDefault {
    public let bytes: Data
    public let format: Ss58AddressFormat
    
    public init(bytes: Data, format: Ss58AddressFormat) throws {
        guard bytes.count == Self.bytesCount else {
            throw SizeMismatchError(size: bytes.count, expected: Self.bytesCount)
        }
        self.bytes = bytes
        self.format = format
    }
    
    public static var typeId: CryptoTypeId { .ed25519 }
    public static var bytesCount: Int = 32
}

public struct Sr25519PublicKey: PublicKey, Hashable, SDefault {
    public let bytes: Data
    public let format: Ss58AddressFormat
    
    public init(bytes: Data, format: Ss58AddressFormat) throws {
        guard bytes.count == Self.bytesCount else {
            throw SizeMismatchError(size: bytes.count, expected: Self.bytesCount)
        }
        self.bytes = bytes
        self.format = format
    }
    
    public static var typeId: CryptoTypeId { .sr25519 }
    public static var bytesCount: Int = 32
}

public struct EcdsaPublicKey: PublicKey, Hashable, SDefault {
    public let bytes: Data
    public let format: Ss58AddressFormat
    
    public init(bytes: Data, format: Ss58AddressFormat) throws {
        guard bytes.count == Self.bytesCount else {
            throw SizeMismatchError(size: bytes.count, expected: Self.bytesCount)
        }
        self.bytes = bytes
        self.format = format
    }
    
    public static var typeId: CryptoTypeId { .ecdsa }
    public static var bytesCount: Int = 33
}
