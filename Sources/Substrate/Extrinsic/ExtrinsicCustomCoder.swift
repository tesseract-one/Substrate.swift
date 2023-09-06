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
    
    public func checkType(info: NetworkType.Info, runtime: Runtime) throws -> Bool {
        info.type.path.last == name
    }
    
    public func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as info: NetworkType.Info, runtime: Runtime
    ) throws {
        guard let bytes = value.bytes else {
            throw Value.EncodingError.wrongShape(actual: value, expected: info.id)
        }
        try encoder.encode(bytes, .fixed(UInt(bytes.count)))
    }
    
    public func validate<C>(
        value: Value<C>, as info: NetworkType.Info, runtime: Runtime
    ) -> Result<Void, TypeError> {
        value.bytes != nil
            ? .success(())
            : .failure(.wrongType(for: value.description, type: info.type,
                                  reason: "Isn't bytes", .get()))
    }
}
