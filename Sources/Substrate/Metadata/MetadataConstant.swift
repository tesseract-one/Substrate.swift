//
//  MetadataConstant.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public class MetadataConstantInfo {
    public let name: String
    public let type: DType
    public let value: Data
    public let documentation: String
    
    public init(runtime: RuntimeConstantMetadata) throws {
        name = runtime.name
        type = try DType(parse: runtime.type)
        value = runtime.value
        documentation = runtime.documentation.joined(separator: "\n")
    }
    
    public func parsed<T: ScaleDynamicDecodable>(_ t: T.Type, registry: TypeRegistryProtocol) throws -> T {
        return try registry.decode(static: t, as: type, from: SCALE.default.decoder(data: value))
    }
    
    public func get(registry: TypeRegistryProtocol) throws -> DValue {
        return try registry.decode(dynamic: type, from: SCALE.default.decoder(data: value))
    }
}
