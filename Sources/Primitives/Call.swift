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
}

public protocol DynamicCall: AnyCall {
    var params: [DValue] { get }
}

public protocol StaticCall: AnyCall {
    static var MODULE: String { get }
    static var FUNCTION: String { get }
    
    init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
    func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
}

extension StaticCall {
    public var module: String { return Self.MODULE }
    public var function: String { return Self.FUNCTION }
}

public protocol Call: StaticCall {
    associatedtype Module: ModuleProtocol
}

extension Call {
    public static var MODULE: String { return Module.NAME }
}

// Dynamic call for encoding
public struct DCall: DynamicCall {
    public let module: String
    public let function: String
    public let params: [DValue]
    
    public init(module: String, function: String, params: [DValue]) {
        self.module = module
        self.function = function
        self.params = params
    }
}
