//
//  Call.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public protocol AnyCall {
    var module: String { get }
    var function: String { get }
    var params: [ScaleDynamicCodable] { get }
}

public protocol Call: AnyCall {
    static var MODULE: Module.Type { get }
    static var FUNCTION: String { get }
    
    init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

extension Call {
    public var module: String { return Self.MODULE.NAME }
    public var function: String { return Self.FUNCTION }
}

// Generic call
public struct DCall: AnyCall {
    public let module: String
    public let function: String
    public let params: [ScaleDynamicCodable]
    
    public init(module: String, function: String, params: [ScaleDynamicCodable]) {
        self.module = module
        self.function = function
        self.params = params
    }
}
