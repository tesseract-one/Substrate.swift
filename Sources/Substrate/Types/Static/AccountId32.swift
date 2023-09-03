//
//  AccountId32.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct AccountId32: StaticAccountId, Hashable, Equatable {
    public typealias DecodingContext = RuntimeSwiftCodableContext
    public typealias EncodingContext = RuntimeSwiftCodableContext
    
    public let raw: Data
    public let runtime: any Runtime
    
    public init(checked raw: Data, runtime: any Runtime) throws {
        self.raw = raw
        self.runtime = runtime
    }
    
    public init(pub: any PublicKey, runtime: any Runtime) throws {
        switch pub.algorithm {
        case .ed25519, .sr25519:
            try self.init(raw: pub.raw, runtime: runtime)
        case .ecdsa:
            let hash: Data = HBlake2b256.instance.hash(data: pub.raw)
            try self.init(checked: hash, runtime: runtime)
        }
    }
    
    public static func == (lhs: AccountId32, rhs: AccountId32) -> Bool {
        lhs.raw == rhs.raw && lhs.runtime.addressFormat == rhs.runtime.addressFormat
    }
    
    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(raw)
        hasher.combine(runtime.addressFormat)
    }
    
    public static let byteCount: Int = 32
}

extension AccountId32: ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        let _ = try Self.validate(runtime: runtime, type: type).get()
        return .bytes(raw, type)
    }
}

extension AccountId32: VoidValueRepresentable {
    public func asValue() -> Value<Void> { .bytes(raw) }
}

extension AccountId32: CustomStringConvertible {
    public var description: String { string }
}
