//
//  AnyHash.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ContextCodable

public struct AnyHash: Hash {
    public typealias DecodingContext = TypeDefinition.Lazy
    
    public let raw: Data
    
    public init(unchecked raw: Data) {
        self.raw = raw
    }
    
    public init(raw: Data, type lazy: TypeDefinition.Lazy) throws
    {
        let type = try lazy()
        guard let count = type.asBytes() else {
            throw TypeError.wrongType(for: Self.self, type: type,
                                      reason: "Isn't bytes", .get())
        }
        guard count == 0 || count == raw.count else {
            throw TypeError.wrongValuesCount(for: Self.self,
                                             expected: raw.count, type: type, .get())
        }
        self.raw = raw
    }
    
    public init(from decoder: Swift.Decoder, context: DecodingContext) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(raw: data, type: context)
    }
    
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        Data.validate(as: type, in: runtime)
    }
}
