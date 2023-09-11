//
//  AnyHash.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ContextCodable

public struct AnyHash: Hash {
    public typealias DecodingContext = () throws -> Int
    
    public let raw: Data
    
    public init(unchecked raw: Data) {
        self.raw = raw
    }
    
    public init(raw: Data, bits: () throws -> Int) throws
    {
        let bits = try bits()
        guard raw.count == bits / 8 else {
            throw SizeMismatchError(size: raw.count,
                                    expected: bits / 8)
        }
        self.raw = raw
    }
    
    public init(from decoder: Swift.Decoder, context: DecodingContext) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(raw: data, bits: context)
    }
    
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        Data.validate(as: type, in: runtime)
    }
}
