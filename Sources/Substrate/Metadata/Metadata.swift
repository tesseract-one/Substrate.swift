//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public protocol RuntimeMetadata {
    var version: UInt8 { get }
    
    func asMetadata() throws -> Metadata
    
    static var versions: Set<UInt32> { get }
}

public protocol Metadata {
    var extrinsic: ExtrinsicMetadata { get }
    var pallets: [String] { get }
    var apis: [String] { get }
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
    func resolve(type path: [String]) -> RuntimeTypeInfo?
    func resolve(pallet index: UInt8) -> PalletMetadata?
    func resolve(pallet name: String) -> PalletMetadata?
    func resolve(api name: String) -> RuntimeApiMetadata?
}

public protocol PalletMetadata {
    var name: String { get }
    var index: UInt8 { get }
    var call: RuntimeTypeInfo? { get }
    var event: RuntimeTypeInfo? { get }
    var storage: [String] { get }
    var constants: [String] { get }
    
    func callName(index: UInt8) -> String?
    func callIndex(name: String) -> UInt8?
    func eventName(index: UInt8) -> String?
    func eventIndex(name: String) -> UInt8?
    
    func storage(name: String) -> StorageMetadata?
    func constant(name: String) -> ConstantMetadata?
}

public protocol StorageMetadata {
    var name: String { get }
    var modifier: StorageEntryModifier { get }
    var types: (keys: [(StorageHasher, RuntimeTypeInfo)], value: RuntimeTypeInfo) { get }
    var defaultValue: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicMetadata {
    var version: UInt8 { get }
    var type: RuntimeTypeInfo { get }
    var extensions: [ExtrinsicExtensionMetadata] { get }
}

public protocol ConstantMetadata {
    var name: String { get }
    var type: RuntimeTypeInfo { get }
    var value: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicExtensionMetadata {
    var identifier: String { get }
    var type: RuntimeTypeInfo { get }
    var additionalSigned: RuntimeTypeInfo { get }
}

public protocol RuntimeApiMetadata {
    var name: String { get }
    var methods: [String] { get }
    
    func resolve(method name: String) -> (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)?
}

public enum MetadataError: Error {
    case storageBadHashersCount(expected: Int, got: Int, name: String, pallet: String)
    case storageNonCompositeKey(name: String, pallet: String, type: RuntimeTypeInfo)
}

public struct OpaqueMetadata: ScaleDecodable, ScaleRuntimeDecodable {
    public let raw: Data
    
    public init(from decoder: ScaleCodec.ScaleDecoder) throws {
        self.raw = try decoder.decode()
    }
    
    public func metadata<C: Config>(config: C) throws -> any Metadata {
        try config.decoder(data: raw).decode(VersionedMetadata.self).metadata
    }
}
