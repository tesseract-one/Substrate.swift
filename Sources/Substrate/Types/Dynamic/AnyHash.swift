//
//  AnyHash.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct AnyHash: Hash {
    public let raw: Data
    
    public init(unchecked raw: Data) {
        self.raw = raw
    }
    
    public init(raw: Data,
                metadata: any Metadata,
                id: @escaping () throws -> RuntimeType.Id) throws
    {
        let type = try id()
        guard let info = metadata.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let count = info.asBytes(metadata) else {
            throw ValueRepresentableError.wrongType(got: info, for: "AnyHash")
        }
        guard count == 0 || count == raw.count else {
            throw SizeMismatchError(size: raw.count, expected: Int(count))
        }
        self.raw = raw
    }
    
    public init(from decoder: Swift.Decoder, context: DecodingContext) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(raw: data, metadata: context.metadata, id: context.id)
    }
}