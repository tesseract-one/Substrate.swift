//
//  ExtrinsicCustomCoder.swift
//  
//
//  Created by Yehor Popovych on 25/07/2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicCustomDynamicCoder: RuntimeCustomDynamicCoder {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func checkType(id: RuntimeType.Id, runtime: Runtime) throws -> Bool {
        guard let definition = runtime.resolve(type: id) else {
            throw Value<RuntimeType.Id>.DecodingError.typeNotFound(id)
        }
        return definition.path.last == name
    }
    
    public func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as id: RuntimeType.Id, runtime: Runtime
    ) throws {
        guard let bytes = value.bytes else {
            throw Value.EncodingError.wrongShape(actual: value, expected: id)
        }
        try encoder.encode(bytes, .fixed(UInt(bytes.count)))
    }
}
