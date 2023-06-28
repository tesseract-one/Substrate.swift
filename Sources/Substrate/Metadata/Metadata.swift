//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public protocol RuntimeMetadata: ScaleCodec.Codable {
    var version: UInt8 { get }
    
    func asMetadata() throws -> Metadata
    
    static var versions: Set<UInt32> { get }
}

public protocol Metadata {
    var extrinsic: ExtrinsicMetadata { get }
    // Swith to non optional after v14 drop
    var enums: OuterEnumsMetadata? { get }
    var pallets: [String] { get }
    var apis: [String] { get }
    
    // Search is O(n). Try to resolve directly by path
    func search(type cb: @escaping ([String]) -> Bool) -> RuntimeTypeInfo?
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
    // Make non optional after v14 metadata drop
    var addressType: RuntimeTypeInfo? { get }
    var callType: RuntimeTypeInfo? { get }
    var signatureType: RuntimeTypeInfo? { get }
    var extraType: RuntimeTypeInfo? { get }
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

public protocol OuterEnumsMetadata {
    var callType: RuntimeTypeInfo { get }
    var eventType: RuntimeTypeInfo { get }
    var moduleErrorType: RuntimeTypeInfo { get }
}

public enum MetadataError: Error {
    case storageBadHashersCount(expected: Int, got: Int, name: String, pallet: String)
    case storageNonCompositeKey(name: String, pallet: String, type: RuntimeTypeInfo)
}

public struct OpaqueMetadata: ScaleCodec.Codable, RuntimeDecodable {
    public let raw: Data
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        self.raw = try decoder.decode()
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(raw)
    }
    
    public func metadata<C: Config>(config: C) throws -> any Metadata {
        var decoder = config.decoder(data: raw)
        return try decoder.decode(VersionedMetadata.self).metadata.asMetadata()
    }
}
