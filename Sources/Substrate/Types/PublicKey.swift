//
//  PublicKey.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import ScaleCodec

public protocol PublicKey: RuntimeCodable, Hashable, Equatable {
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(_ raw: Data) throws
    
    func account<A: AccountId>(runtime: any Runtime) throws -> A
    func address<A: Address>(runtime: any Runtime) throws -> A
}

public extension PublicKey {
    @inlinable
    static func from(ss58: String) throws -> (Self, SS58.AddressFormat){
        let (raw, format) = try SS58.decode(string: ss58)
        return try (Self(raw), format)
    }
    
    @inlinable
    func ss58(format: SS58.AddressFormat) -> String {
        SS58.encode(data: raw, format: format)
    }
    
    @inlinable
    func account<A: AccountId>(runtime: any Runtime) throws -> A {
        try A(pub: self, runtime: runtime)
    }
    
    @inlinable
    func address<A: Address>(runtime: any Runtime) throws -> A {
        let account: A.TAccountId = try self.account(runtime: runtime)
        return try A(accountId: account, runtime: runtime)
    }
    
    @inlinable
    func account<S: SomeSubstrate>(in substrate: S) throws -> S.RC.TAccountId {
        try account(runtime: substrate.runtime)
    }
    
    @inlinable
    func address<S: SomeSubstrate>(in substrate: S) throws -> S.RC.TAddress {
        try address(runtime: substrate.runtime)
    }
}

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
