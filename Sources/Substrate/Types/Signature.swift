//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 18.04.2023.
//

import Foundation
import ScaleCodec

public protocol Signature: ScaleRuntimeCodable {
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws
    static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId]
}

public extension Signature {
    init(fake algorithm: CryptoTypeId, runtime: any Runtime) throws {
        let sig = Data(repeating: 1, count: algorithm.signatureBytesCount)
        try self.init(raw: sig, algorithm: algorithm, runtime: runtime)
    }
}

public extension CryptoTypeId {
    var signatureBytesCount: Int {
        switch self {
        case .sr25519, .ed25519: return 64
        case .ecdsa: return 65
        }
    }
}

public struct EcdsaSignature: ScaleFixedData, Signature, Hashable, Equatable, CustomStringConvertible {
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

public struct Ed25519Signature: ScaleFixedData, Signature, Hashable, Equatable, CustomStringConvertible {
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

public struct Sr25519Signature: ScaleFixedData, Signature, Hashable, Equatable, CustomStringConvertible {
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

public enum MultiSignature: Hashable, Equatable, CustomStringConvertible {
    case ed25519(Ed25519Signature)
    case sr25519(Sr25519Signature)
    case ecdsa(EcdsaSignature)
}

extension MultiSignature: Signature {
    public init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        switch algorithm {
        case .ecdsa:
            self = try .ecdsa(EcdsaSignature(decoding: raw))
        case .ed25519:
            self = try .ed25519(Ed25519Signature(decoding: raw))
        case .sr25519:
            self = try .sr25519(Sr25519Signature(decoding: raw))
        }
    }
    
    public var algorithm: CryptoTypeId {
        switch self {
        case .ed25519: return .ed25519
        case .ecdsa: return .ecdsa
        case .sr25519: return .sr25519
        }
    }
    
    public var raw: Data {
        switch self {
        case .ecdsa(let sig): return sig.raw
        case .sr25519(let sig): return sig.raw
        case .ed25519(let sig): return sig.raw
        }
    }
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { Self.supportedCryptoTypes }
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

extension MultiSignature: ScaleRuntimeCodable {}

public extension Signature {
    var description: String {
        "\(algorithm)(\(raw.hex()))"
    }
}
