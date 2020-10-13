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
    
    var path: [ScaleRegistryEncodable] { get }
    
    func prefix(registry: TypeRegistry) throws -> Data
    func key(registry: TypeRegistry) throws -> Data
}

public protocol StorageKey: AnyStorageKey {
    associatedtype Value: ScaleRegistryDecodable
    
    static var MODULE: Module.Type { get }
    static var FIELD: String { get }
}

extension AnyStorageKey {
    public func prefix(registry: TypeRegistry) throws -> Data {
        return try registry.metadata.prefix(for: self, with: registry)
    }
    
    public func key(registry: TypeRegistry) throws -> Data {
        return try registry.metadata.key(for: self, with: registry)
    }
}

extension StorageKey {
    public var module: String { return Self.MODULE.NAME }
    public var field: String { return Self.FIELD }
}

// Generic storage key
public struct SStorageKey: AnyStorageKey {
    public let module: String
    public let field: String
    public let path: [ScaleRegistryEncodable]
    
    public init(module: String, field: String, path: [ScaleRegistryEncodable]) {
        self.module = module
        self.path = path
        self.field = field
    }
}
