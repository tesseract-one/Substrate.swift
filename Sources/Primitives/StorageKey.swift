//
//  StorageKey.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol AnyStorageKey {
    associatedtype Value
    var module: String { get }
    var field: String { get }
}

public protocol StaticStorageKey: AnyStorageKey where Value: ScaleDynamicDecodable {
    associatedtype Module: ModuleProtocol
    static var MODULE: String { get }
    static var FIELD: String { get }
    
    func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data
    func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data
}

extension StaticStorageKey {
    public static var MODULE: String { return Module.NAME }
    public var module: String { return Self.MODULE }
    public var field: String { return Self.FIELD }
}

public protocol PlainStorageKey: StaticStorageKey {}

extension PlainStorageKey {
    public func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        throw TypeRegistryError.storageItemBadItemType(
            module: module, field: field, type: "Plain", expected: "Map"
        )
    }
    
    public func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data { Data() }
}

public protocol MapStorageKey: StaticStorageKey {
    func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
}

extension MapStorageKey {
    public func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard h1 == nil else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "DoubleMap", expected: "Map"
            )
        }
        return Data()
    }
    
    public func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Plain", expected: "Map"
            )
        }
        let encoder = SCALE.default.encoder()
        try encodeKey(in: encoder, registry: registry)
        return h1.hash(data: encoder.output)
    }
}

public protocol DoubleMapStorageKey: StaticStorageKey {
    func encodeKey1(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
    func encodeKey2(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws
}

extension DoubleMapStorageKey {
    public func iteratorKey(h1: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Map", expected: "DoubleMap"
            )
        }
        let encoder = SCALE.default.encoder()
        try encodeKey1(in: encoder, registry: registry)
        return h1.hash(data: encoder.output)
    }
    
    public func key(h1: Hasher?, h2: Hasher?, registry: TypeRegistryProtocol) throws -> Data {
        guard let h1 = h1 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Plain", expected: "DoubleMap"
            )
        }
        guard let h2 = h2 else {
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Map", expected: "DoubleMap"
            )
        }
        let encoder1 = SCALE.default.encoder()
        try encodeKey1(in: encoder1, registry: registry)
        let data = h1.hash(data: encoder1.output)
        let encoder2 = SCALE.default.encoder()
        try encodeKey2(in: encoder2, registry: registry)
        return data + h2.hash(data: encoder2.output)
    }
}

public protocol DynamicStorageKey: AnyStorageKey where Value == DValue {
    var path: [ScaleDynamicEncodable] { get }
    
    func iteratorKey(h1: Hasher?, type: DType?, registry: TypeRegistryProtocol) throws -> Data
    func key(h1: Hasher?, h2: Hasher?, types: [DType], registry: TypeRegistryProtocol) throws -> Data
}

extension DynamicStorageKey {
    public func iteratorKey(h1: Hasher?, type: DType?, registry: TypeRegistryProtocol) throws -> Data {
        switch path.count {
        case 1:
            guard h1 == nil, type == nil else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "DoubleMap", expected: "Map"
                )
            }
            return Data()
        case 2:
            guard let h1 = h1, let type = type else {
                throw TypeRegistryError.storageItemBadItemType(
                    module: module, field: field, type: "Map", expected: "DoubleMap"
                )
            }
            let encoder = SCALE.default.encoder()
            try registry.encode(value: path[0], type: type, in: encoder)
            return h1.hash(data: encoder.output)
        default:
            throw TypeRegistryError.storageItemBadItemType(
                module: module, field: field, type: "Plain", expected: "Map"
            )
        }
    }
    
    public func key(h1: Hasher?, h2: Hasher?, types: [DType], registry: TypeRegistryProtocol) throws -> Data {
        guard types.count == path.count else {
            throw TypeRegistryError.storageItemBadPathTypes(
                module: module, field: field, path: path, expected: types
            )
        }
        var data = Data()
        if path.count > 0 {
            let encoder = SCALE.default.encoder()
            try registry.encode(value: path[0], type: types[0], in: encoder)
            data += h1!.hash(data: encoder.output)
        }
        if path.count > 1 {
            let encoder = SCALE.default.encoder()
            try registry.encode(value: path[1], type: types[1], in: encoder)
            data += h2!.hash(data: encoder.output)
        }
        return data
    }
}

// Generic storage key
public struct DStorageKey: DynamicStorageKey {
    public let module: String
    public let field: String
    public let path: [ScaleDynamicEncodable]
    
    public init(module: String, field: String, path: [ScaleDynamicEncodable]) {
        self.module = module
        self.path = path
        self.field = field
    }
}
