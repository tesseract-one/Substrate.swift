//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 18.04.2023.
//

import Foundation
import ScaleCodec

public protocol Signature: RuntimeDynamicCodable, ValueRepresentable {
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(raw: Data, algorithm: CryptoTypeId,
         runtime: any Runtime, id: @escaping RuntimeType.LazyId) throws
    static func algorithms(runtime: any Runtime,
                           id: @escaping RuntimeType.LazyId) throws -> [CryptoTypeId]
}

public extension Signature {
    @inlinable
    init(fake algorithm: CryptoTypeId, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        let sig = Data(repeating: 1, count: algorithm.signatureBytesCount)
        try self.init(raw: sig, algorithm: algorithm, runtime: runtime, id: id)
    }
    
    var description: String {
        "\(algorithm)(\(raw.hex()))"
    }
}

public protocol StaticSignature: Signature, RuntimeCodable {
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws
    static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId]
}

public extension StaticSignature {
    @inlinable
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        try self.init(raw: raw, algorithm: algorithm, runtime: runtime)
    }
    
    @inlinable
    static func algorithms(runtime: any Runtime,
                           id: @escaping RuntimeType.LazyId) throws -> [CryptoTypeId]
    {
        try Self.algorithms(runtime: runtime)
    }
    
    func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let count = info.asBytes(runtime) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        let bytes = raw
        guard count == 0 || bytes.count == count else {
            throw ValueRepresentableError.wrongValuesCount(in: info, expected: bytes.count,
                                                           for: String(describing: Self.self))
        }
        return .bytes(bytes, type)
    }
    
    func asValue() -> Value<Void> { .bytes(raw) }
}

public extension CryptoTypeId {
    var signatureBytesCount: Int {
        switch self {
        case .sr25519, .ed25519: return 64
        case .ecdsa: return 65
        }
    }
}

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

public enum MultiSignature: Hashable, Equatable, CustomStringConvertible {
    case ed25519(Ed25519Signature)
    case sr25519(Sr25519Signature)
    case ecdsa(EcdsaSignature)
}

extension MultiSignature: StaticSignature {
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
    
    public var signature: any Signature {
        switch self {
        case .ecdsa(let sig): return sig
        case .sr25519(let sig): return sig
        case .ed25519(let sig): return sig
        }
    }
    
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { Self.supportedCryptoTypes }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.sr25519, .ecdsa, .ed25519]
}

extension MultiSignature: ValueRepresentable {
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let selfvars = Set(Self.supportedCryptoTypes.map{$0.signatureName})
        guard case .variant(variants: let variants) = info.definition.flatten(metadata: runtime.metadata) else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiSignature")
        }
        guard selfvars == Set(variants.map{$0.name}) else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiSignature")
        }
        let sig = self.signature
        guard let field = variants.first(where: {$0.name == sig.algorithm.signatureName})?.fields.first else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiSignature")
        }
        return try .variant(name: sig.algorithm.signatureName,
                            values: [sig.asValue(runtime: runtime, type: field.type)], type)
    }
}

extension MultiSignature: ScaleCodec.Codable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .ed25519(decoder.decode())
        case 1: self = try .sr25519(decoder.decode())
        case 2: self = try .ecdsa(decoder.decode())
        default: throw decoder.enumCaseError(for: opt)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        switch self {
        case .ed25519(let s):
            try encoder.encode(0, .enumCaseId)
            try encoder.encode(s)
        case .sr25519(let s):
            try encoder.encode(1, .enumCaseId)
            try encoder.encode(s)
        case .ecdsa(let s):
            try encoder.encode(2, .enumCaseId)
            try encoder.encode(s)
        }
    }
}

extension MultiSignature: RuntimeCodable, RuntimeDynamicCodable {}
