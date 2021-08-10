//
//  Call.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public protocol AnyCall: ScaleDynamicCodable {
    var module: String { get }
    var function: String { get }
    
    // TODO: Provide better dynamic typisation (DYNAMIC)
    var params: Dictionary<String, Any> { get }
    
    static func decode(headerFrom decoder: ScaleDecoder) throws -> (module: UInt8, call: UInt8)
    static func encode(header: (module: UInt8, call: UInt8), in encoder: ScaleEncoder) throws
}

public protocol StaticCall: AnyCall {
    static var MODULE: String { get }
    static var FUNCTION: String { get }
    
    init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
    func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
}

public protocol Call: StaticCall {
    associatedtype Module: ModuleProtocol
}

extension AnyCall {
    public static func decode(headerFrom decoder: ScaleDecoder) throws -> (module: UInt8, call: UInt8) {
        let module = try decoder.decode(UInt8.self)
        let call = try decoder.decode(UInt8.self)
        return (module: module, call: call)
    }
    
    public static func encode(header: (module: UInt8, call: UInt8), in encoder: ScaleEncoder) throws {
        try encoder.encode(header.module)
        try encoder.encode(header.call)
    }
}

extension StaticCall {
    public var module: String { return Self.MODULE }
    public var function: String { return Self.FUNCTION }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let header = try Self.decode(headerFrom: decoder)
        let info = try registry.info(forCall: header)
        guard Self.MODULE == info.module && Self.FUNCTION == info.call else {
            throw TypeRegistryError.callFoundWrongCall(module: info.module,
                                                       function: info.call,
                                                       exmodule: Self.MODULE,
                                                       exfunction: Self.FUNCTION)
        }
        try self.init(decodingParamsFrom: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let header = try registry.header(forCall: function, in: module)
        try Self.encode(header: header, in: encoder)
        try self.encode(paramsIn: encoder, registry: registry)
    }
}

extension Call {
    public static var MODULE: String { return Module.NAME }
}

// Dynamic call for encoding
public struct DCall: AnyCall {
    public let module: String
    public let function: String
    public let params: Dictionary<String, Any>
    
    public init(module: String, function: String, params: [String: DValue]) {
        self.module = module
        self.function = function
        self.params = params
    }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let header = try Self.decode(headerFrom: decoder)
        let info = try registry.info(forCall: header)
        try self.init(module: info.module, function: info.call, decoder: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let header = try registry.header(forCall: function, in: module)
        try Self.encode(header: header, in: encoder)
        let types = try registry.types(forCall: function, in: module)
        guard types.count == params.count else {
            throw TypeRegistryError.callEncodingWrongParametersCount(
                call: self, count: params.count, expected: types.count
            )
        }
        for (name, type) in types {
            guard let param = params[name] else {
                throw TypeRegistryError.callEncodingMissingParameter(call: self,
                                                                     parameter: name,
                                                                     type: type)
            }
            // TODO: Better encoding (DYNAMIC)
            try registry.encode(dynamic: param as! DValue, type: type, in: encoder)
        }
    }
    
    public init(module: String, function: String, decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self.module = module
        self.function = function
        
        let types = try registry.types(forCall: function, in: module)
        let kvs = try types.map { (name, type) in
            // TODO: Better decoding (DYNAMIC)
            (name, try registry.decode(dynamic: type, from: decoder))
        }
        self.params = Dictionary(uniqueKeysWithValues: kvs)
    }
}
