//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public typealias LatestMetadata = MetadataV15

public protocol Metadata {
    var extrinsic: ExtrinsicMetadata { get }
    
    // Swith to non optional after v14 drop
    var outerEnums: OuterEnumsMetadata? { get }
    var customTypes: Dictionary<String, (NetworkType.Id, Data)>? { get }
    
    var pallets: [String] { get }
    var apis: [String] { get }
    
    func resolve(type id: NetworkType.Id) -> NetworkType?
    // Path is joined by "."
    func resolve(type path: String) -> NetworkType.Info?
    // Search and reduce is O(n). Try to resolve by id or by path
    func search(type cb: (String) -> Bool) -> NetworkType.Info?
    func reduce<R>(
        types into: R,
        _ cb: (inout R, NetworkType.Info) throws -> Void
    ) rethrows -> R
    
    func resolve(pallet index: UInt8) -> PalletMetadata?
    func resolve(pallet name: String) -> PalletMetadata?
    func resolve(api name: String) -> RuntimeApiMetadata?
}

public protocol PalletMetadata {
    var name: String { get }
    var index: UInt8 { get }
    var call: NetworkType.Info? { get }
    var event: NetworkType.Info? { get }
    var error: NetworkType.Info? { get }
    var storage: [String] { get }
    var constants: [String] { get }
    
    func callName(index: UInt8) -> String?
    func callIndex(name: String) -> UInt8?
    func callParams(name: String) -> [(field: NetworkType.Field, type: NetworkType)]?
    func eventName(index: UInt8) -> String?
    func eventIndex(name: String) -> UInt8?
    func eventParams(name: String) -> [(field: NetworkType.Field, type: NetworkType)]?
    
    func storage(name: String) -> StorageMetadata?
    func constant(name: String) -> ConstantMetadata?
}

public protocol StorageMetadata {
    var name: String { get }
    var modifier: LatestMetadata.StorageEntryModifier { get }
    var types: (keys: [(hasher: LatestMetadata.StorageHasher, type: NetworkType.Info)],
                value: NetworkType.Info) { get }
    var defaultValue: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicMetadata {
    var version: UInt8 { get }
    var type: NetworkType.Info { get }
    var extensions: [ExtrinsicExtensionMetadata] { get }
    // Make non optional after v14 metadata drop
    var addressType: NetworkType.Info? { get }
    var callType: NetworkType.Info? { get }
    var signatureType: NetworkType.Info? { get }
    var extraType: NetworkType.Info? { get }
}

public protocol ConstantMetadata {
    var name: String { get }
    var type: NetworkType.Info { get }
    var value: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicExtensionMetadata {
    var identifier: String { get }
    var type: NetworkType.Info { get }
    var additionalSigned: NetworkType.Info { get }
}

public protocol RuntimeApiMetadata {
    var name: String { get }
    var methods: [String] { get }
    
    func resolve(
        method name: String
    ) -> (params: [(name: String, type: NetworkType.Info)], result: NetworkType.Info)?
}

public protocol OuterEnumsMetadata {
    var callType: NetworkType.Info { get }
    var eventType: NetworkType.Info { get }
    var moduleErrorType: NetworkType.Info { get }
}

public enum MetadataError: Error {
    case typeNotFound(id: NetworkType.Id)
    case storageBadHashersCount(expected: Int, got: Int, name: String, pallet: String)
    case storageNonCompositeKey(name: String, pallet: String, type: NetworkType.Info)
}

public struct OpaqueMetadata: ScaleCodec.Codable, RuntimeDecodable, IdentifiableType {
    public let raw: Data
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        self.raw = try decoder.decode()
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(raw)
    }
    
    public func metadata<C: Config>(config: C) throws -> any Metadata {
        var decoder = config.decoder(data: raw)
        return try decoder.decode(VersionedNetworkMetadata.self).metadata.asMetadata()
    }
    
    public static var definition: TypeDefinition { .data }
}

public extension Dictionary where Key == NetworkType.Id, Value == NetworkType {
    @inlinable
    func get(_ id: NetworkType.Id) throws -> NetworkType {
        guard let val = self[id] else {
            throw MetadataError.typeNotFound(id: id)
        }
        return val
    }
}
