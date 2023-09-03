//
//  Signatures.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public protocol SingleTypeStaticSignature: StaticSignature, FixedDataCodable, VoidValueRepresentable,
                                           IdentifiableType, Hashable, Equatable,
                                           CustomStringConvertible
{
    var raw: Data { get }
    static var algorithm: CryptoTypeId { get }
}

public extension SingleTypeStaticSignature {
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        guard algorithm == Self.algorithm else {
            throw CryptoError.unsupported(type: algorithm, supports: [Self.algorithm])
        }
        try self.init(decoding: raw)
    }
    
    @inlinable
    init(raw: Data) throws { try self.init(decoding: raw)}
    
    @inlinable
    var algorithm: CryptoTypeId { Self.algorithm }
    
    @inlinable
    func serialize() -> Data { raw }
    
    @inlinable
    static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { [Self.algorithm] }
    
    @inlinable
    static var fixedBytesCount: Int { algorithm.signatureBytesCount }
    
    func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        let _ = try Self.validate(runtime: runtime, type: type).get()
        return .bytes(raw, type)
    }
    
    func asValue() -> Value<Void> { .bytes(raw) }
    
    @inlinable
    static var definition: TypeDefinition { .data(count: UInt32(fixedBytesCount)) }
    
    static func _validate(runtime: any Runtime,
                          type: NetworkType) -> Result<Void, TypeError> {
        return AnySignature.parseTypeInfo(runtime: runtime, type: type).flatMap { types in
            guard types.count == 1, types.values.first == algorithm else {
                return .failure(.wrongType(for: Self.self, got: type,
                                           reason: "Unknown signature type: \(types)"))
            }
            guard let count = type.asBytes(runtime) else {
                return .failure(.wrongType(for: Self.self, got: type,
                                           reason: "Signature is not byte sequence"))
            }
            guard Self.fixedBytesCount == count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: Self.fixedBytesCount,
                                                  in: type))
            }
            return .success(())
        }
    }
}

public struct EcdsaSignature: SingleTypeStaticSignature {
    public let raw: Data
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        raw = data
    }
    
    @inlinable
    public static func validate(runtime: Runtime,
                                type: NetworkType) -> Result<Void, TypeError> {
        _validate(runtime: runtime, type: type)
    }
    
    @inlinable
    public static var algorithm: CryptoTypeId { .ecdsa }
}

public struct Ed25519Signature: SingleTypeStaticSignature {
    public let raw: Data

    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        raw = data
    }
    
    @inlinable
    public static func validate(runtime: Runtime,
                                type: NetworkType) -> Result<Void, TypeError> {
        _validate(runtime: runtime, type: type)
    }
    
    @inlinable
    public static var algorithm: CryptoTypeId { .ed25519 }
}

public struct Sr25519Signature: SingleTypeStaticSignature {
    public let raw: Data
    
    public init(decoding data: Data) throws {
        guard data.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: data.count, expected: Self.fixedBytesCount)
        }
        raw = data
    }
    
    @inlinable
    public static func validate(runtime: Runtime,
                                type: NetworkType) -> Result<Void, TypeError> {
        _validate(runtime: runtime, type: type)
    }
    
    @inlinable
    public static var algorithm: CryptoTypeId { .sr25519 }
}
