//
//  StorageKey.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol AnyStorageKey {
    var module: String { get }
    var field: String { get }
    
    var path: [ScaleDynamicEncodable] { get }
    
    func prefix(registry: TypeRegistryProtocol) throws -> Data
    func key(registry: TypeRegistryProtocol) throws -> Data
    func defaultValue(registry: TypeRegistryProtocol) throws -> DValue
}

public protocol StorageKey: AnyStorageKey {
    associatedtype Value: ScaleDynamicDecodable
    associatedtype Module: ModuleProtocol
    
    func defaultParsedValue(registry: TypeRegistryProtocol) throws -> Value
    
    static var MODULE: String { get }
    static var FIELD: String { get }
}

extension AnyStorageKey {
    public func prefix(registry: TypeRegistryProtocol) throws -> Data {
        return try registry.prefix(for: self)
    }
    
    public func key(registry: TypeRegistryProtocol) throws -> Data {
        return try registry.key(for: self)
    }
    
    public func defaultValue(registry: TypeRegistryProtocol) throws -> DValue {
        return try registry.defaultValue(for: self)
    }
}

extension StorageKey {
    public static var MODULE: String { return Module.NAME }
    public var module: String { return Self.MODULE }
    public var field: String { return Self.FIELD }
    
    public func defaultParsedValue(registry: TypeRegistryProtocol) throws -> Value {
        return try registry.defaultParsedValue(for: self)
    }
}

// Generic storage key
public struct DStorageKey: AnyStorageKey {
    public let module: String
    public let field: String
    public let path: [ScaleDynamicEncodable]
    
    public init(module: String, field: String, path: [ScaleDynamicEncodable]) {
        self.module = module
        self.path = path
        self.field = field
    }
}
