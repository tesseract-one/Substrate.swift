//
//  Error.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation
import ScaleCodec

public protocol ApiError: Error, RuntimeDynamicDecodable, RuntimeDynamicSwiftDecodable {}

public protocol DynamicApiError: ApiError {
    init(value: Value<RuntimeType.Id>, runtime: any Runtime) throws
}

public extension DynamicApiError {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` type: RuntimeType.Id,
                                runtime: any Runtime) throws
    {
        let value = try Value(from: &decoder, as: type, runtime: runtime)
        try self.init(value: value, runtime: runtime)
    }
    
    init(from decoder: Swift.Decoder,
         `as` type: RuntimeType.Id,
         runtime: any Runtime) throws
    {
        let value = try Value(from: decoder, as: type, runtime: runtime)
        try self.init(value: value, runtime: runtime)
    }
}
