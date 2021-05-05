//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec

public protocol Signature: ScaleDynamicCodable {
    init(type: CryptoTypeId, bytes: Data) throws
    
    var typeId: CryptoTypeId { get }
    var bytes: Data { get }
    
    static var supportedCryptoTypes: [CryptoTypeId] { get }
}

public struct EcdsaSignature: ScaleFixedData, Signature {
    public let signature: Data
    
    public static let fixedBytesCount: Int = 65
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        signature = data
    }
    
    public func encode() throws -> Data {
        return signature
    }
    
    public init(type: CryptoTypeId, bytes: Data) throws {
        guard type == .ecdsa else {
            throw CryptoTypeError.wrongType(type: type, expected: Self.supportedCryptoTypes)
        }
        try self.init(decoding: bytes)
    }
    
    public var typeId: CryptoTypeId { .ecdsa }
    public var bytes: Data { signature }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.ecdsa]
}

public struct Ed25519Signature: ScaleFixedData, Signature {
    public let signature: Data
    
    public static let fixedBytesCount: Int = 64
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        signature = data
    }
    
    public func encode() throws -> Data {
        return signature
    }
    
    public init(type: CryptoTypeId, bytes: Data) throws {
        guard type == .ed25519 else {
            throw CryptoTypeError.wrongType(type: type, expected: Self.supportedCryptoTypes)
        }
        try self.init(decoding: bytes)
    }
    
    public var typeId: CryptoTypeId { .ed25519 }
    public var bytes: Data { signature }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.ed25519]
}

public struct Sr25519Signature: ScaleFixedData, Signature {
    public let signature: Data
    
    public static let fixedBytesCount: Int = 64
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        signature = data
    }
    
    public func encode() throws -> Data {
        return signature
    }
    
    public init(type: CryptoTypeId, bytes: Data) throws {
        guard type == .ed25519 else {
            throw CryptoTypeError.wrongType(type: type, expected: Self.supportedCryptoTypes)
        }
        try self.init(decoding: bytes)
    }
    
    public var typeId: CryptoTypeId { .sr25519 }
    public var bytes: Data { signature }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.sr25519]
}

public enum MultiSignature {
    case ed25519(Ed25519Signature)
    case sr25519(Sr25519Signature)
    case ecdsa(EcdsaSignature)
}

extension MultiSignature: Signature {
    public init(type: CryptoTypeId, bytes: Data) throws {
        switch type {
        case .ecdsa:
            self = try .ecdsa(EcdsaSignature(type: type, bytes: bytes))
        case .ed25519:
            self = try .ed25519(Ed25519Signature(type: type, bytes: bytes))
        case .sr25519:
            self = try .sr25519(Sr25519Signature(type: type, bytes: bytes))
        default:
            throw CryptoTypeError.wrongType(
                type: type, expected: Self.supportedCryptoTypes
            )
        }
    }
    
    public var bytes: Data {
        switch self {
        case .ecdsa(let sig): return sig.bytes
        case .sr25519(let sig): return sig.bytes
        case .ed25519(let sig): return sig.bytes
        }
    }
    
    public var typeId: CryptoTypeId {
        switch self {
        case .ed25519: return .ed25519
        case .ecdsa: return .ecdsa
        case .sr25519: return .sr25519
        }
    }
    
    public static let supportedCryptoTypes: [CryptoTypeId] = [.sr25519, .ecdsa, .ed25519]
}

extension MultiSignature: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .ed25519(decoder.decode())
        case 1: self = try .sr25519(decoder.decode())
        case 2: self = try .ecdsa(decoder.decode())
        default: throw decoder.enumCaseError(for: opt)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .ed25519(let s): try encoder.encode(0, .enumCaseId).encode(s)
        case .sr25519(let s): try encoder.encode(1, .enumCaseId).encode(s)
        case .ecdsa(let s): try encoder.encode(2, .enumCaseId).encode(s)
        }
    }
}

extension MultiSignature: ScaleDynamicCodable {}
