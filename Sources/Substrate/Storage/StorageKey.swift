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

public protocol PalletStorageKey: StorageKey, FrameType
    where TBaseParams == Void
{
    static var pallet: String { get }
}

public extension PalletStorageKey {
    @inlinable var pallet: String { Self.pallet }
    @inlinable var frame: String { pallet }
    @inlinable static var frame: String { pallet }
    @inlinable static var frameTypeName: String { "StorageKey" }
}

public typealias StorageKeyTypeInfo = (keys: [(hasher: LatestMetadata.StorageHasher, type: NetworkType.Info)],
                                       value: NetworkType.Info)
public typealias StorageKeyChildTypes = (keys: [(hasher: StaticHasher.Type, type: ValidatableTypeStatic.Type)],
                                         value: ValidatableTypeStatic.Type)

public extension PalletStorageKey where
    Self: ComplexFrameType, TypeInfo == StorageKeyTypeInfo
{
    @inlinable
    static func typeInfo(runtime: any Runtime) -> Result<TypeInfo, FrameTypeError> {
        guard let info = runtime.resolve(storage: name, pallet: pallet) else {
            return .failure(.typeInfoNotFound(for: Self.self, .get()))
        }
        return .success((info.keys, info.value))
    }
}

public protocol StaticStorageKey<TValue>: PalletStorageKey, RuntimeDecodable {
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
        if runtime.resolve(storage: name, pallet: pallet) == nil {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, .get())
        }
    }
    
    static func defaultValue(base: TBaseParams, runtime: any Runtime) throws -> TValue {
        guard let (_, _, data) = runtime.resolve(storage: name, pallet: pallet) else {
            throw StorageKeyCodingError.storageNotFound(name: name, pallet: pallet)
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

public extension StorageKeyRootIterator where TKey: PalletStorageKey {
    @inlinable init() { self.init(base: ()) }
}

public extension StorageKeyRootIterator where TKey: StaticStorageKey {
    @inlinable var hash: Data { Self.hash }
    @inlinable static var hash: Data { TKey.prefix }
}

public extension StorageKeyIterator where TKey: StaticStorageKey {
    func decode<D: ScaleCodec.Decoder>(keyFrom decoder: inout D, runtime: any Runtime) throws -> TKey {
        try TKey(from: &decoder, runtime: runtime)
    }
}

public extension ComplexStaticFrameType
    where TypeInfo == StorageKeyTypeInfo, ChildTypes == StorageKeyChildTypes
{
    static func validate(info: TypeInfo,
                         runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        let ourTypes = childTypes
        guard ourTypes.keys.count == info.keys.count else {
            return .failure(.wrongFieldsCount(for: Self.self, expected: ourTypes.keys.count,
                                              got: info.keys.count, .get()))
        }
        return zip(ourTypes.keys, info.keys).enumerated().voidErrorMap { index, zip in
            let (our, info) = zip
            guard our.hasher.hasherType == info.hasher else {
                return .failure(
                    .paramMismatch(for: Self.self, index: index,
                                   expected: our.hasher.hasherType.name,
                                   got: info.hasher.name, .get())
                )
            }
            return our.type.validate(runtime: runtime, type: info.type).mapError {
                .childError(for: Self.self, index: index, error: $0, .get())
            }
        }.flatMap {
            ourTypes.value.validate(runtime: runtime, type: info.value) .mapError {
                .childError(for: Self.self, index: -1, error: $0, .get())
            }
        }
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

public enum StorageKeyCodingError: Error {
    case storageNotFound(name: String, pallet: String)
    case badCountOfPathComponents(has: Int, expected: Int)
    case badPrefix(has: Data, expected: Data)
}
