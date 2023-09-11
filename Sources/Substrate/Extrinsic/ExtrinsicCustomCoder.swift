//
//  ExtrinsicCustomCoder.swift
//  
//
//  Created by Yehor Popovych on 25/07/2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicCustomDynamicCoder: RuntimeCustomDynamicCoder, CustomDynamicCoder {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func check(type: TypeDefinition) -> Bool {
        type.name.hasSuffix(name)
    }
    
    public func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws {
        guard let bytes = value.bytes else {
            throw Value.EncodingError.wrongShape(actual: value, expected: type.strong)
        }
        try encoder.encode(bytes, .fixed(UInt(bytes.count)))
    }
    
    public func validate<C>(
        value: Value<C>, as type: TypeDefinition, in runtime: Runtime
    ) -> Result<Void, TypeError> {
        value.bytes != nil
            ? .success(())
            : .failure(.wrongType(for: value.description, type: type,
                                  reason: "Isn't bytes", .get()))
    }
}
