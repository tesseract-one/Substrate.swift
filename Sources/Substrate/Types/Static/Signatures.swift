//
//  Signatures.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct EcdsaSignature: FixedDataCodable, StaticSignature, VoidValueRepresentable,
                              Hashable, Equatable, CustomStringConvertible
{
    public let signature: Data
    
    public init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        guard algorithm == .ecdsa else {
            throw CryptoError.unsupported(type: algorithm, supports: Self.supportedCryptoTypes)
        }
        try self.init(decoding: raw)
    }
    
    public init(raw: Data) throws {
        try self.init(decoding: raw)
    }
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        signature = data
    }
    
    public func serialize() -> Data { signature }
    
    public var algorithm: CryptoTypeId { .ecdsa }
    public var raw: Data { signature }
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { Self.supportedCryptoTypes }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.ecdsa]
    public static let fixedBytesCount: Int = CryptoTypeId.ecdsa.signatureBytesCount
}

public struct Ed25519Signature: FixedDataCodable, StaticSignature, VoidValueRepresentable,
                                Hashable, Equatable, CustomStringConvertible
{
    public let signature: Data
    
    public init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        guard algorithm == .ed25519 else {
            throw CryptoError.unsupported(type: algorithm, supports: Self.supportedCryptoTypes)
        }
        try self.init(decoding: raw)
    }
    
    public init(raw: Data) throws {
        try self.init(decoding: raw)
    }
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        signature = data
    }
    
    public func serialize() -> Data { signature }
    
    public var algorithm: CryptoTypeId { .ed25519 }
    public var raw: Data { signature }
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { Self.supportedCryptoTypes }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.ed25519]
    public static let fixedBytesCount: Int = CryptoTypeId.ed25519.signatureBytesCount
}

public struct Sr25519Signature: FixedDataCodable, StaticSignature, VoidValueRepresentable,
                                Hashable, Equatable, CustomStringConvertible
{
    public let signature: Data
    
    public init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        guard algorithm == .ed25519 else {
            throw CryptoError.unsupported(type: algorithm, supports: Self.supportedCryptoTypes)
        }
        try self.init(decoding: raw)
    }
    
    public init(raw: Data) throws {
        try self.init(decoding: raw)
    }
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        signature = data
    }
    
    public func serialize() -> Data { signature }
    
    public var algorithm: CryptoTypeId { .sr25519 }
    public var raw: Data { signature }
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { Self.supportedCryptoTypes }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.sr25519]
    public static let fixedBytesCount: Int = CryptoTypeId.sr25519.signatureBytesCount
}
