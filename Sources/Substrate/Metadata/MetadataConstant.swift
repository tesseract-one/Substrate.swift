//
//  MetadataConstant.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public class MetadataConstant {
    public let name: String
    public let type: SType
    public let value: Data
    public let documentation: String
    
    public init(runtime: RuntimeConstantMetadata) throws {
        name = runtime.name
        type = try SType(runtime.type)
        value = runtime.value
        documentation = runtime.documentation.joined(separator: "\n")
    }
    
    public func parsed<T: ScaleDecodable>(_ t: T.Type) throws -> T {
        return try T(from: SCALE.default.decoder(data: value))
    }
    
    public func get(with registry: TypeRegistry) throws -> ScaleRegistryDecodable {
        let decoder = SCALE.default.decoder(data: value)
        return try registry.metadata.decode(type: type, from: decoder, with: registry)
    }
}
