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
    
    func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D, runtime: any Runtime) throws -> TValue
    
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
    
    func decode<D: ScaleCodec.Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey
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

public protocol StaticStorageKey<TValue>: StorageKey, PalletType, RuntimeDecodable where TBaseParams == Void {
    init(_ params: TParams, runtime: any Runtime) throws
    init<D: ScaleCodec.Decoder>(decodingPath decoder: inout D, runtime: any Runtime) throws
    var pathHash: Data { get }
    
    static func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D, runtime: any Runtime) throws -> TValue
}

public extension StaticStorageKey {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let prefix = Self.prefix
        let decodedPrefix = try decoder.decode(.fixed(UInt(prefix.count)))
        guard decodedPrefix == prefix else {
            throw StorageKeyCodingError.badPrefix(has: decodedPrefix, expected: prefix)
        }
        try self.init(decodingPath: &decoder, runtime: runtime)
    }
    
    var hash: Data { self.prefix + self.pathHash }
    
    init(base: Void, params: TParams, runtime: any Runtime) throws {
        try self.init(params, runtime: runtime)
    }
    
    func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D, runtime: Runtime) throws -> TValue {
        try Self.decode(valueFrom: &decoder, runtime: runtime)
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
        var decoder = runtime.decoder(with: data)
        return try decode(valueFrom: &decoder, runtime: runtime)
    }
    
    static var prefix: Data { prefix(name: name, pallet: pallet) }
}

public extension StaticStorageKey where TValue: RuntimeDecodable {
    static func decode<D: ScaleCodec.Decoder>(
        valueFrom decoder: inout D, runtime: Runtime
    ) throws -> TValue {
        try TValue(from: &decoder, runtime: runtime)
    }
}

public extension StorageKeyRootIterator where TKey: StaticStorageKey {
    @inlinable init() { self.init(base: ()) }
    @inlinable var hash: Data { Self.hash }
    @inlinable static var hash: Data { TKey.prefix }
}

public extension StorageKeyIterator where TKey: StaticStorageKey {
    func decode<D: ScaleCodec.Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey {
        try TKey(from: &decoder, runtime: runtime)
    }
}

public protocol DynamicStorageKey: IterableStorageKey where
    TParams == [ValueRepresentable],
    TBaseParams == (name: String, pallet: String),
    TIterator: IterableStorageKeyIterator,
    TIterator.TIterator: DynamicStorageKeyIterator {}

public protocol DynamicStorageKeyIterator: IterableStorageKeyIterator where
    TParam == ValueRepresentable,
    TKey: DynamicStorageKey
{
    init(name: String, pallet: String, params: [ValueRepresentable], runtime: any Runtime) throws
}

public protocol SomeStorageChangeSet<THash>: RuntimeSwiftDecodable {
    associatedtype THash: Hash
    var block: THash { get }
    var changes: [(key: Data, value: Data?)] { get }
}

public protocol ValidatableStorageKey: StaticStorageKey, RuntimeValidatable
    where TValue: RuntimeDynamicValidatable
{
    static var keyPath: [(any RuntimeDynamicValidatable.Type, any StaticHasher.Type)] { get }
}

public extension ValidatableStorageKey {
    static func validate(path: [(RuntimeType.Id, MetadataV14.StorageHasher)],
                         runtime: any Runtime) -> Result<Void, ValidationError>
    {
        let ownKp = keyPath
        guard path.count == ownKp.count else {
            return .failure(.wrongFieldsCount(for: Self.self,
                                              expected: ownKp.count,
                                              got: path.count))
        }
        return zip(ownKp, path).voidErrorMap { key, info in
            guard key.1.name == info.1.hasher.name else {
                return .failure(.paramMismatch(for: Self.self, expected: key.1.name,
                                               got: info.1.hasher.name))
            }
            return key.0.validate(runtime: runtime, type: info.0).mapError {
                .childError(for: Self.self, error: $0)
            }
        }
    }
    
    static func validate(runtime: any Runtime) -> Result<Void, ValidationError> {
        guard let info = runtime.resolve(storage: name, pallet: pallet) else {
            return .failure(.infoNotFound(for: Self.self))
        }
        return validate(path: info.keys.map {($0.1.id, $0.0)}, runtime: runtime).flatMap {
            TValue.validate(runtime: runtime, type: info.value.id).mapError {
                .childError(for: Self.self, error: $0)
            }
        }
    }
}

public enum StorageKeyCodingError: Error {
    case storageNotFound(name: String, pallet: String)
    case badCountOfPathComponents(has: Int, expected: Int)
    case badPrefix(has: Data, expected: Data)
}
