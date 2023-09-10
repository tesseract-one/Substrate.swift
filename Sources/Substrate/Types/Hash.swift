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
    where DecodingContext == TypeDefinition.Lazy
{
    var raw: Data { get }
    
    init(raw: Data, type: TypeDefinition.Lazy) throws
}

public extension Hash {
    var description: String { raw.hex() }
    
    @inlinable
    init(raw: Data, type: TypeDefinition) throws {
        try self.init(raw: raw) { type }
    }
    
    func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
    
    func asValue(of type: TypeDefinition,
                 in runtime: any Runtime) throws -> Value<TypeDefinition>
    {
        guard let count = type.asBytes() else {
            throw TypeError.wrongType(for: Self.self, type: type,
                                      reason: "isn't byte array", .get())
        }
        guard count == 0 || raw.count == count else {
            throw TypeError.wrongValuesCount(for: Self.self, expected: raw.count,
                                             type: type, .get())
        }
        return .bytes(raw, type)
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
    init(raw: Data, type: TypeDefinition.Lazy) throws
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
    
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>
    ) -> TypeDefinition.Builder {
        .array(count: UInt32(fixedBytesCount), of: registry.def(UInt8.self))
    }
}

public struct SizeMismatchError: Error {
    public let size: Int
    public let expected: Int
    
    public init(size: Int, expected: Int) {
        self.size = size; self.expected = expected
    }
}
