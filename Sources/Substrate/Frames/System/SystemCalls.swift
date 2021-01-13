//
//  SystemCalls.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct SetCodeCall<S: System> {
    /// Runtime wasm blob.
    public let code: Data
}

extension SetCodeCall: Call {
    public static var MODULE: Module.Type { SystemModule<S>.self }
    public static var FUNCTION: String { "SetCode" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        code = try decoder.decode()
    }
    
    public var params: [ScaleDynamicCodable] { [code] }
}

public struct SetCodeWithoutChecksCall<S: System> {
    /// Runtime wasm blob.
    public let code: Data
}

extension SetCodeWithoutChecksCall: Call {
    public static var MODULE: Module.Type { SystemModule<S>.self }
    public static var FUNCTION: String { "SetCodeWithoutChecks" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        code = try decoder.decode()
    }
    
    public var params: [ScaleDynamicCodable] { [code] }
}
