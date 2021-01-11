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
}

public protocol StorageKey: AnyStorageKey {
    associatedtype Value: ScaleDynamicDecodable
    
    static var MODULE: Module.Type { get }
    static var FIELD: String { get }
}

extension AnyStorageKey {
    public func prefix(registry: TypeRegistryProtocol) throws -> Data {
        return try registry.prefix(for: self)
    }
    
    public func key(registry: TypeRegistryProtocol) throws -> Data {
        return try registry.key(for: self)
    }
}

extension StorageKey {
    public var module: String { return Self.MODULE.NAME }
    public var field: String { return Self.FIELD }
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
