//
//  AccountId.swift
//  
//
//  Created by Yehor Popovych on 17.04.2023.
//

import Foundation
import ScaleCodec

public protocol AccountId: RuntimeLazyDynamicCodable, RuntimeLazyDynamicSwiftCodable,
                           ValueRepresentable, ValidatableType
{
    init(from string: String, runtime: any Runtime,
         type: TypeDefinition.Lazy) throws
    init(pub: any PublicKey, runtime: any Runtime,
         type: TypeDefinition.Lazy) throws
    init(raw: Data, runtime: any Runtime,
         type: TypeDefinition.Lazy) throws
    
    var raw: Data { get }
    var string: String { get }
    var runtime: any Runtime { get }
}

public extension AccountId {
    init(from string: String, runtime: any Runtime,
         type: TypeDefinition.Lazy) throws
    {
        let (raw, format) = try SS58.decode(string: string)
        guard format == runtime.addressFormat else {
            throw SS58.Error.formatNotAllowed
        }
        try self.init(raw: raw, runtime: runtime, type: type)
    }
    
    var string: String {
        try! SS58.encode(data: raw, format: runtime.addressFormat)
    }
    
    func address<A: Address>() throws -> A where A.TAccountId == Self {
        try runtime.create(address: A.self, account: self)
    }
}

public protocol StaticAccountId: AccountId, IdentifiableType, RuntimeCodable, RuntimeSwiftCodable {
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
        try self.init(from: string, runtime: runtime, type: TypeDefinition.Never)
    }
    
    init(pub: any PublicKey, runtime: any Runtime, type: TypeDefinition.Lazy) throws
    {
        try self.init(pub: pub, runtime: runtime)
    }
    
    init(raw: Data, runtime: any Runtime, type: TypeDefinition.Lazy) throws
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
    
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .array(count: UInt32(self.byteCount), of: registry.def(UInt8.self))
    }
}
