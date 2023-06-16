//
//  StorageKey.swift
//  
//
//  Created by Yehor Popovych on 08.03.2023.
//

import Foundation
import ScaleCodec

public protocol StorageKey<TValue> {
    associatedtype TParams
    associatedtype TBaseParams
    associatedtype TValue
    
    var pallet: String { get }
    var name: String { get }
    
    var hash: Data { get }
    
    init(base: TBaseParams, params: TParams, runtime: any Runtime) throws
    
    func decode(valueFrom decoder: ScaleDecoder, runtime: any Runtime) throws -> TValue
    
    static func defaultValue(base: TBaseParams, runtime: any Runtime) throws -> TValue
    static func validate(base: TBaseParams, runtime: any Runtime) throws
}

public extension StorageKey {
    var prefix: Data { Self.prefix(name: self.name, pallet: self.pallet) }
    
    static func prefix(name: String, pallet: String) -> Data {
        HXX128.instance.hash(data: Data(pallet.utf8)) +
            HXX128.instance.hash(data: Data(name.utf8))
    }
}

public protocol StorageKeyIterator<TKey> {
    associatedtype TParam
    associatedtype TKey: StorageKey
    
    var hash: Data { get }
    
    func decode(keyFrom decoder: ScaleDecoder, runtime: any Runtime) throws -> TKey
}

public protocol StorageKeyRootIterator<TKey>: StorageKeyIterator where TParam == TKey.TBaseParams {
    init(base: TParam)
}

public protocol IterableStorageKeyIterator<TKey>: StorageKeyIterator {
    associatedtype TIterator: StorageKeyIterator<TKey>
    
    func next(param: TIterator.TParam, runtime: any Runtime) throws -> TIterator
}

public protocol IterableStorageKey: StorageKey {
    associatedtype TIterator: StorageKeyRootIterator<Self>
}

public protocol StaticStorageKey<TValue>: StorageKey, ScaleRuntimeDecodable where TBaseParams == Void {
    static var pallet: String { get }
    static var name: String { get }
    
    init(_ params: TParams, runtime: any Runtime) throws
    init(decodingPath decoder: ScaleDecoder, runtime: any Runtime) throws
    var pathHash: Data { get }
    
    static func decode(valueFrom decoder: ScaleDecoder, runtime: any Runtime) throws -> TValue
}

public extension StaticStorageKey {
    var pallet: String { Self.pallet }
    var name: String { Self.name }

    init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        let prefix = Self.prefix
        let decodedPrefix = try decoder.decode(.fixed(UInt(prefix.count)))
        guard decodedPrefix == prefix else {
            throw StorageKeyCodingError.badPrefix(has: decodedPrefix, expected: prefix)
        }
        try self.init(decodingPath: decoder, runtime: runtime)
    }
    
    var hash: Data { self.prefix + self.pathHash }
    
    init(base: Void, params: TParams, runtime: any Runtime) throws {
        try self.init(params, runtime: runtime)
    }
    
    func decode(valueFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TValue {
        try Self.decode(valueFrom: decoder, runtime: runtime)
    }
    
    static func validate(base: TBaseParams, runtime: any Runtime) throws {
        if runtime.resolve(storage: Self.name, pallet: Self.pallet) == nil {
            throw StorageKeyCodingError.storageNotFound(name: Self.name, pallet: Self.pallet)
        }
    }
    
    static func defaultValue(base: TBaseParams, runtime: any Runtime) throws -> TValue {
        guard let (_, _, data) = runtime.resolve(storage: Self.name, pallet: Self.pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: Self.name, pallet: Self.pallet)
        }
        return try decode(valueFrom: runtime.decoder(with: data), runtime: runtime)
    }
    
    static var prefix: Data { prefix(name: name, pallet: pallet) }
}

public extension StaticStorageKey where TValue: ScaleRuntimeDecodable {
    static func decode(valueFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TValue {
        try TValue(from: decoder, runtime: runtime)
    }
}

public extension StorageKeyRootIterator where TKey: StaticStorageKey {
    init() { self.init(base: ()) }
}

public extension StorageKeyIterator where TKey: StaticStorageKey {
    func decode(keyFrom decoder: ScaleDecoder, runtime: any Runtime) throws -> TKey {
        try TKey(from: decoder, runtime: runtime)
    }
}

public enum StorageKeyCodingError: Error {
    case storageNotFound(name: String, pallet: String)
    case badCountOfPathComponents(has: Int, expected: Int)
    case badPrefix(has: Data, expected: Data)
}
