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
    init(value: Value<RuntimeTypeId>) throws
    
    static func errorType(runtime: any Runtime) throws -> RuntimeTypeInfo
}

public extension DynamicApiError {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        let type = try Self.errorType(runtime: runtime)
        let value = try Value(from: &decoder, as: type.id, runtime: runtime)
        try self.init(value: value)
    }
    
    init(from decoder: Swift.Decoder) throws {
        let type = try Self.errorType(runtime: decoder.runtime)
        let value = try Value(from: decoder, as: type.id)
        try self.init(value: value)
    }
}
