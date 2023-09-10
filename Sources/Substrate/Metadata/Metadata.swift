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
    var version: UInt8 { get }
    var extrinsic: ExtrinsicMetadata { get }
    
    // Swith to non optional after v14 drop
    var outerEnums: OuterEnumsMetadata? { get }
    var customTypes: Dictionary<String, (TypeDefinition, Data)>? { get }
    
    var pallets: [String] { get }
    var apis: [String] { get }
    
    // Path is joined by "."
    func resolve(type path: String) -> TypeDefinition?
    // Search and reduce is O(n). Try to resolve by id or by path
    func search(type cb: (String) -> Bool) -> TypeDefinition?
    func reduce<R>(
        types into: R,
        _ cb: (inout R, TypeDefinition) throws -> Void
    ) rethrows -> R
    
    func resolve(pallet index: UInt8) -> PalletMetadata?
    func resolve(pallet name: String) -> PalletMetadata?
    func resolve(api name: String) -> RuntimeApiMetadata?
}

public protocol PalletMetadata {
    var name: String { get }
    var index: UInt8 { get }
    var call: TypeDefinition? { get }
    var event: TypeDefinition? { get }
    var error: TypeDefinition? { get }
    var storage: [String] { get }
    var constants: [String] { get }
    
    func callName(index: UInt8) -> String?
    func callIndex(name: String) -> UInt8?
    func callParams(name: String) -> [TypeDefinition.Field]?
    func eventName(index: UInt8) -> String?
    func eventIndex(name: String) -> UInt8?
    func eventParams(name: String) -> [TypeDefinition.Field]?
    
    func storage(name: String) -> StorageMetadata?
    func constant(name: String) -> ConstantMetadata?
}

public protocol StorageMetadata {
    var name: String { get }
    var modifier: LatestMetadata.StorageEntryModifier { get }
    var types: (keys: [(hasher: LatestMetadata.StorageHasher, type: TypeDefinition)],
                value: TypeDefinition) { get }
    var defaultValue: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicMetadata {
    var version: UInt8 { get }
    // remove after v14 drop
    var type: TypeDefinition? { get }
    var extensions: [ExtrinsicExtensionMetadata] { get }
    // Make non optional after v14 metadata drop
    var addressType: TypeDefinition? { get }
    var callType: TypeDefinition? { get }
    var signatureType: TypeDefinition? { get }
    var extraType: TypeDefinition? { get }
}

public protocol ConstantMetadata {
    var name: String { get }
    var type: TypeDefinition { get }
    var value: Data { get }
    var documentation: [String] { get }
}

public protocol ExtrinsicExtensionMetadata {
    var identifier: String { get }
    var type: TypeDefinition { get }
    var additionalSigned: TypeDefinition { get }
}

public protocol RuntimeApiMetadata {
    var name: String { get }
    var methods: [String] { get }
    
    func resolve(
        method name: String
    ) -> (params: [(name: String, type: TypeDefinition)], result: TypeDefinition)?
}

public protocol OuterEnumsMetadata {
    var callType: TypeDefinition { get }
    var eventType: TypeDefinition { get }
    var moduleErrorType: TypeDefinition { get }
}

public enum MetadataError: Error {
    case typeNotFound(id: NetworkType.Id, info: ErrorMethodInfo)
    case badBitSequenceFormat(type: NetworkType, reason: String,
                              info: ErrorMethodInfo)
    case storageBadHashersCount(expected: Int, got: Int,
                                name: String, pallet: String,
                                info: ErrorMethodInfo)
    case storageNonCompositeKey(name: String, pallet: String,
                                type: TypeDefinition, info: ErrorMethodInfo)
    case typeIsNotVariant(type: TypeDefinition, info: ErrorMethodInfo)
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
    
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder
    {
        .sequence(of: registry.def(UInt8.self))
    }
}
