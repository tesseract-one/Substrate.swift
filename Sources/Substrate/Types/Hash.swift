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
                      ValueRepresentable, VoidValueRepresentable,
                      ValidatableRuntimeType, Equatable, CustomStringConvertible
    where DecodingContext == (metadata: any Metadata, id: () throws -> RuntimeType.Id)
{
    var raw: Data { get }
    
    init(raw: Data,
         metadata: any Metadata,
         id: () throws -> RuntimeType.Id) throws
}

public extension Hash {
    var description: String { raw.hex() }
    
    @inlinable
    init(raw: Data,
         runtime: any Runtime,
         id: RuntimeType.LazyId) throws
    {
        try self.init(raw: raw, metadata: runtime.metadata) { try id(runtime) }
    }
    
    func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
    
    func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let count = info.asBytes(runtime) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        guard count == 0 || raw.count == count else {
            throw ValueRepresentableError.wrongValuesCount(in: info, expected: raw.count,
                                                           for: String(describing: Self.self))
        }
        return .bytes(raw, type)
    }
     
    func asValue() -> Value<Void> {
         .bytes(raw)
     }
}

public protocol StaticHash: Hash, FixedDataCodable, RuntimeCodable, Swift.Decodable {
    init(raw: Data) throws
}

public extension StaticHash {
    @inlinable
    init(raw: Data,
         metadata: any Metadata,
         id: () throws -> RuntimeType.Id) throws
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
    
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, TypeValidationError> {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
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

public struct SizeMismatchError: Error {
    public let size: Int
    public let expected: Int
    
    public init(size: Int, expected: Int) {
        self.size = size; self.expected = expected
    }
}
