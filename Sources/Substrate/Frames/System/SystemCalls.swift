//
//  SystemCalls.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct SystemSetCodeCall<S: System> {
    /// Runtime wasm blob.
    public let code: Data
}

extension SystemSetCodeCall: Call {
    public typealias Module = SystemModule<S>
    
    public static var FUNCTION: String { "set_code" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        code = try decoder.decode()
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try code.encode(in: encoder, registry: registry)
    }
}

public struct SystemSetCodeWithoutChecksCall<S: System> {
    /// Runtime wasm blob.
    public let code: Data
}

extension SystemSetCodeWithoutChecksCall: Call {
    public typealias Module = SystemModule<S>
    
    public static var FUNCTION: String { "set_code_without_checks" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        code = try decoder.decode()
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try code.encode(in: encoder, registry: registry)
    }
}
