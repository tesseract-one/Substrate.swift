//
//  AccountId.swift
//  
//
//  Created by Yehor Popovych on 17.04.2023.
//

import Foundation
import ScaleCodec

public protocol AccountId: RuntimeDynamicCodable, RuntimeDynamicSwiftCodable, ValueRepresentable {
    init(from string: String, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    init(pub: any PublicKey, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    init(raw: Data, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    
    var raw: Data { get }
    var string: String { get }
    var runtime: any Runtime { get }
}

public extension AccountId {
    init(from string: String, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        let (raw, format) = try SS58.decode(string: string)
        guard format == runtime.addressFormat else {
            throw SS58.Error.formatNotAllowed
        }
        try self.init(raw: raw, runtime: runtime, id: id)
    }
    
    var string: String {
        SS58.encode(data: raw, format: runtime.addressFormat)
    }
    
    func address<A: Address>() throws -> A where A.TAccountId == Self {
        try runtime.create(address: A.self, account: self)
    }
}

public protocol StaticAccountId: AccountId, RuntimeCodable, RuntimeSwiftCodable {
    init(checked raw: Data, runtime: any Runtime) throws
    
    init(from string: String, runtime: any Runtime) throws
    init(pub: any PublicKey, runtime: any Runtime) throws
    init(raw: Data, runtime: any Runtime) throws
    
    static var byteCount: Int { get }
}

public extension StaticAccountId {
    init(raw: Data, runtime: any Runtime) throws {
        guard raw.count == Self.byteCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.byteCount)
        }
        try self.init(checked: raw, runtime: runtime)
    }
    
    init(from string: String, runtime: any Runtime) throws {
        try self.init(from: string, runtime: runtime, id: RuntimeType.IdNever)
    }
    
    init(from string: String, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        try self.init(from: string, runtime: runtime)
    }
    
    init(pub: any PublicKey, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        try self.init(pub: pub, runtime: runtime)
    }
    
    init(raw: Data, runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        try self.init(raw: raw, runtime: runtime)
    }
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        let raw = try decoder.decode(.fixed(UInt(Self.byteCount)))
        try self.init(checked: raw, runtime: runtime)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
        try encoder.encode(raw, .fixed(UInt(Self.byteCount)))
    }
    
    init(from decoder: Swift.Decoder, runtime: Runtime) throws {
        let container = try decoder.singleValueContainer()
        if let u8arr = try? container.decode([UInt8].self) {
            try self.init(raw: Data(u8arr), runtime: runtime)
        } else if let data = try? container.decode(Data.self) {
            try self.init(raw: data, runtime: runtime)
        } else {
            let string = try container.decode(String.self)
            try self.init(from: string, runtime: runtime)
        }
    }
    
    func encode(to encoder: Swift.Encoder, runtime: Runtime) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.string)
    }
}

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
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
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
}

extension AccountId32: VoidValueRepresentable {
    public func asValue() -> Value<Void> { .bytes(raw) }
}

extension AccountId32: CustomStringConvertible {
    public var description: String { string }
}
