//
//  Signatures.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public protocol SingleTypeStaticSignature: StaticSignature, FixedDataCodable, VoidValueRepresentable,
                                           ValidatableRuntimeType, Hashable, Equatable,
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
    
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, TypeValidationError> {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        return AnySignature.parseTypeInfo(runtime: runtime, typeId: id).flatMap { types in
            guard types.count == 1, types.values.first == algorithm else {
                return .failure(.wrongType(got: info, for: String(describing: Self.self)))
            }
            guard let count = info.asBytes(runtime) else {
                return .failure(.wrongType(got: info, for: String(describing: Self.self)))
            }
            guard Self.fixedBytesCount == count else {
                return .failure(.wrongValuesCount(in: info, expected: Self.fixedBytesCount,
                                                  for: String(describing: Self.self)))
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
    public static var algorithm: CryptoTypeId { .sr25519 }
}
