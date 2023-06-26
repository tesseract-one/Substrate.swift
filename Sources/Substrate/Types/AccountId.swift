//
//  AccountId.swift
//  
//
//  Created by Yehor Popovych on 17.04.2023.
//

import Foundation
import ScaleCodec

public protocol AccountId: RuntimeCodable, Swift.Codable, ValueRepresentable {
    init(from string: String, runtime: any Runtime) throws
    init(pub: any PublicKey, runtime: any Runtime) throws
    init(raw: Data, runtime: any Runtime) throws
    
    var raw: Data { get }
    var string: String { get }
    var runtime: any Runtime { get }
}

public extension AccountId {
    init(from string: String, runtime: any Runtime) throws {
        let (raw, format) = try SS58.decode(string: string)
        guard format == runtime.addressFormat else {
            throw SS58.Error.formatNotAllowed
        }
        try self.init(raw: raw, runtime: runtime)
    }
    
    init(from decoder: Swift.Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let u8arr = try? container.decode([UInt8].self) {
            try self.init(raw: Data(u8arr), runtime: decoder.runtime)
        } else if let data = try? container.decode(Data.self) {
            try self.init(raw: data, runtime: decoder.runtime)
        } else {
            let string = try container.decode(String.self)
            try self.init(from: string, runtime: decoder.runtime)
        }
    }
    
    var string: String {
        SS58.encode(data: raw, format: runtime.addressFormat)
    }
    
    func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.string)
    }
}

public protocol StaticAccountId: AccountId {
    init(checked raw: Data, runtime: any Runtime) throws
    
    static var byteCount: Int { get }
}

public extension StaticAccountId {
    init(raw: Data, runtime: any Runtime) throws {
        guard raw.count == Self.byteCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.byteCount)
        }
        try self.init(checked: raw, runtime: runtime)
    }
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        let raw = try decoder.decode(.fixed(UInt(Self.byteCount)))
        try self.init(checked: raw, runtime: runtime)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
        try encoder.encode(raw, .fixed(UInt(Self.byteCount)))
    }
}

public struct AccountId32: StaticAccountId, Hashable, Equatable {
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
            let hash = HBlake2b256.instance.hash(data: pub.raw)
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
    public func asValue() throws -> Value<Void> { .bytes(raw) }
}

extension AccountId32: CustomStringConvertible {
    public var description: String { string }
}
