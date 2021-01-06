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
        type = try DType(runtime.type)
        value = runtime.value
        documentation = runtime.documentation.joined(separator: "\n")
    }
    
    public func parsed<T: ScaleDynamicDecodable>(_ t: T.Type, meta: MetadataProtocol) throws -> T {
        guard meta.registry.hasValueType(t, for: type) else {
            throw TypeRegistryError.typeNotFound(type)
        }
        return try T(from: SCALE.default.decoder(data: value), meta: meta)
    }
    
    public func get(meta: MetadataProtocol) throws -> DValue {
        let decoder = SCALE.default.decoder(data: value)
        return try meta.decode(type: type, from: decoder)
    }
}
