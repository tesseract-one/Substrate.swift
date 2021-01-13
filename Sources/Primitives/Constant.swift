//
//  Constant.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation

public protocol AnyConstant {
    var module: String { get }
    var name: String { get }

    func value(registry: TypeRegistryProtocol) throws -> DValue
}

extension AnyConstant {
    public func value(registry: TypeRegistryProtocol) throws -> DValue {
        return try registry.value(of: self)
    }
}

public protocol Constant: AnyConstant {
    associatedtype Value: ScaleDynamicDecodable
    associatedtype Module: ModuleProtocol
    
    func value(parsed registry: TypeRegistryProtocol) throws -> Value
    
    static var MODULE: String { get }
    static var NAME: String { get }
}

extension Constant {
    public func value(parsed registry: TypeRegistryProtocol) throws -> Value {
        return try registry.value(parsed: self)
    }
    public static var MODULE: String { Module.NAME }
    public var module: String { Self.MODULE }
    public var name: String { Self.NAME }
}

public struct DConstant: AnyConstant {
    public var module: String
    public var name: String
    
    public init(module: String, name: String) {
        self.module = module
        self.name = name
    }
}
