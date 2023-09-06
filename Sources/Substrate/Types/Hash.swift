//
//  Hash.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec
import ContextCodable

public protocol Hash: ContextDecodable, Swift.Encodable,
                      VoidValueRepresentable, ValueRepresentable,
                      ValidatableType, Equatable, CustomStringConvertible
    where DecodingContext == (metadata: any Metadata, id: () throws -> NetworkType.Id)
{
    var raw: Data { get }
    
    init(raw: Data,
         metadata: any Metadata,
         id: () throws -> NetworkType.Id) throws
}

public extension Hash {
    var description: String { raw.hex() }
    
    @inlinable
    init(raw: Data,
         runtime: any Runtime,
         id: NetworkType.LazyId) throws
    {
        try self.init(raw: raw, metadata: runtime.metadata) { try id(runtime) }
    }
    
    func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
    
    func asValue(runtime: Runtime, type: NetworkType.Info) throws -> Value<NetworkType.Id> {
        guard let count = type.type.asBytes(runtime) else {
            throw TypeError.wrongType(for: Self.self, type: type.type,
                                      reason: "isn't byte array", .get())
        }
        guard count == 0 || raw.count == count else {
            throw TypeError.wrongValuesCount(for: Self.self, expected: raw.count,
                                             type: type.type, .get())
        }
        return .bytes(raw, type.id)
    }
     
    func asValue() -> Value<Void> {
         .bytes(raw)
     }
}

public protocol StaticHash: Hash, IdentifiableType, FixedDataCodable, RuntimeCodable, Swift.Decodable {
    init(raw: Data) throws
}

public extension StaticHash {
    @inlinable
    init(raw: Data,
         metadata: any Metadata,
         id: () throws -> NetworkType.Id) throws
    {
        try self.init(raw: raw)
    }
    
    init(from decoder: Swift.Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(raw: data)
    }
    
    @inlinable
    init(decoding data: Data) throws {
       try self.init(raw: data)
    }
    
    @inlinable
    init(from decoder: Swift.Decoder, context: DecodingContext) throws {
        try self.init(from: decoder)
    }
    
    @inlinable
    func serialize() -> Data { raw }
    
    @inlinable
    static var definition: TypeDefinition {
        .data(count: UInt32(Self.fixedBytesCount))
    }
}

public struct SizeMismatchError: Error {
    public let size: Int
    public let expected: Int
    
    public init(size: Int, expected: Int) {
        self.size = size; self.expected = expected
    }
}
