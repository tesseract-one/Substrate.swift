//
//  AnyHash.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ContextCodable

public struct AnyHash: Hash {
    public typealias DecodingContext = (metadata: any Metadata, id: () throws -> NetworkType.Id)
    
    public let raw: Data
    
    public init(unchecked raw: Data) {
        self.raw = raw
    }
    
    public init(raw: Data,
                metadata: any Metadata,
                id: () throws -> NetworkType.Id) throws
    {
        let type = try id()
        guard let info = metadata.resolve(type: type) else {
            throw TypeError.typeNotFound(for: Self.self, id: type, .get())
        }
        guard let count = info.asBytes(metadata) else {
            throw TypeError.wrongType(for: Self.self, type: info,
                                      reason: "Isn't bytes", .get())
        }
        guard count == 0 || count == raw.count else {
            throw TypeError.wrongValuesCount(for: Self.self,
                                             expected: raw.count, type: info, .get())
        }
        self.raw = raw
    }
    
    public init(from decoder: Swift.Decoder, context: DecodingContext) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(raw: data, metadata: context.metadata, id: context.id)
    }
    
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError> {
        Data.validate(runtime: runtime, type: type)
    }
}
