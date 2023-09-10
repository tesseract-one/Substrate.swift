//
//  MetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023.
//

import Foundation

public final class MetadataV15: Metadata {
    public let version: UInt8
    public let extrinsic: ExtrinsicMetadata
    public let outerEnums: OuterEnumsMetadata?
    public let customTypes: Dictionary<String, (TypeDefinition, Data)>?
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { Array(apisByName.keys) }
    
    public let types: NetworkTypeRegistry
    public let typesByName: [String: TypeDefinition]
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    public let apisByName: [String: RuntimeApi]!
    
    public init(network: Network) throws {
        let types = try TypeRegistry.from(network: network.types).get()
        self.types = types
        self.version = network.version
        let byNamePairs = types.types.compactMap { kv in
            (kv.value.name, kv.value.weak)
        }
        self.typesByName = Dictionary(byNamePairs) { (l, r) in l }
        self.extrinsic = try Extrinsic(network: network.extrinsic, types: types)
        let pallets = try network.pallets.map { try Pallet(network: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.index, $0) })
        self.apisByName = try Dictionary(
            uniqueKeysWithValues: network.apis.map {
                try ($0.name, RuntimeApi(network: $0, types: types))
            }
        )
        self.outerEnums = try OuterEnums(network: network.outerEnums, types: types)
        self.customTypes = try network.custom.mapValues { try (types.get($0.0, .get()), $0.1) }
    }
    
//    @inlinable
//    public func resolve(type id: NetworkType.Id) -> NetworkType? { types[id] }
    
    @inlinable
    public func resolve(type path: String) -> TypeDefinition? { typesByName[path] }
    
    @inlinable
    public func search(type cb: (String) -> Bool) -> TypeDefinition? {
        typesByName.first{cb($0.key)}?.value
    }
    
    @inlinable public func reduce<R>(
        types into: R,
        _ cb: (inout R, TypeDefinition) throws -> Void
    ) rethrows -> R {
        try types.types.reduce(into: into) { r, e in try cb(&r, e.value.weak) }
    }
    
    @inlinable
    public func resolve(pallet index: UInt8) -> PalletMetadata? { palletsByIndex[index] }
    
    @inlinable
    public func resolve(pallet name: String) -> PalletMetadata? { palletsByName[name] }
    
    @inlinable
    public func resolve(api name: String) -> RuntimeApiMetadata? { apisByName[name] }
}

public extension MetadataV15 {
    typealias Constant = MetadataV14.Constant
    typealias Storage = MetadataV14.Storage
    typealias ExtrinsicExtension = MetadataV14.ExtrinsicExtension
    typealias StorageEntryModifier = Network.StorageEntryModifier
    typealias StorageHasher = Network.StorageHasher
    
    final class Pallet: PalletMetadata {
        public let name: String
        public let index: UInt8
        public let call: TypeDefinition?
        public let event: TypeDefinition?
        public let error: TypeDefinition?
        
        public let callNameByIdx: [UInt8: String]?
        public let callByName: [String: TypeDefinition.Variant]?
        
        public let eventNameByIdx: [UInt8: String]?
        public let eventByName: [String: TypeDefinition.Variant]?
        
        public let storageByName: [String: Storage]?
        public var storage: [String] {
            storageByName.map { Array($0.keys) } ?? []
        }
        
        public let constantByName: [String: Constant]
        public var constants: [String] {
            Array(constantByName.keys)
        }
        
        public init(network: Network.Pallet, types: NetworkTypeRegistry) throws {
            self.name = network.name
            self.index = network.index
            self.call = try network.call.map { try types.get($0, .get()) }
            self.event = try network.event.map { try types.get($0, .get()) }
            self.error = try network.error.map { try types.get($0, .get()) }
            let calls = try self.call.map { try Self.variants(for: $0, .get()) }
            self.callByName = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0) })
            }
            self.callNameByIdx = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            let events = try self.event.map { try Self.variants(for: $0, .get()) }
            self.eventByName = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0) })
            }
            self.eventNameByIdx = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.storageByName = try network.storage
                .flatMap {
                    try $0.entries.map {
                        try ($0.name, Storage(network: $0, pallet: network.name,
                                              types: types))
                    }
                }.flatMap { Dictionary(uniqueKeysWithValues: $0) }
            self.constantByName = try Dictionary(
                uniqueKeysWithValues: network.constants.map {
                    ($0.name, try Constant(network: $0, types: types))
                }
            )
        }
        
        @inlinable
        public func callName(index: UInt8) -> String? { callNameByIdx?[index] }
        
        @inlinable
        public func callIndex(name: String) -> UInt8? { callByName?[name]?.index }
        
        @inlinable
        public func callParams(name: String) -> [TypeDefinition.Field]? {
            callByName?[name]?.fields
        }
        
        @inlinable
        public func eventName(index: UInt8) -> String? { eventNameByIdx?[index] }
        
        @inlinable
        public func eventIndex(name: String) -> UInt8? { eventByName?[name]?.index }
        
        @inlinable
        public func eventParams(name: String) -> [TypeDefinition.Field]? {
            eventByName?[name]?.fields
        }
        
        @inlinable
        public func constant(name: String) -> ConstantMetadata? { constantByName[name] }
        
        @inlinable
        public func storage(name: String) -> StorageMetadata? { storageByName?[name] }
        
        private static func variants(for def: TypeDefinition, _ info: ErrorMethodInfo) throws -> [TypeDefinition.Variant] {
            guard case .variant(variants: let vars) = def.definition else {
                throw MetadataError.typeIsNotVariant(type: def.strong, info: info)
            }
            return vars
        }
    }
}

public extension MetadataV15 {
    struct Extrinsic: ExtrinsicMetadata {
        public let version: UInt8
        public let addressType: TypeDefinition?
        public let callType: TypeDefinition?
        public let signatureType: TypeDefinition?
        public let extraType: TypeDefinition?
        public let extensions: [ExtrinsicExtensionMetadata]
        
        public var type: TypeDefinition? { nil }
        
        public init(network: Network.Extrinsic, types: NetworkTypeRegistry) throws {
            self.version = network.version
            self.addressType = try types.get(network.addressType, .get())
            self.callType = try types.get(network.callType, .get())
            self.signatureType = try types.get(network.signatureType, .get())
            self.extraType = try types.get(network.extraType, .get())
            self.extensions = try network.signedExtensions.map {
                try ExtrinsicExtension(network: $0, types: types)
            }
        }
    }
}

public extension MetadataV15 {
    struct RuntimeApi: RuntimeApiMetadata {
        public let name: String
        public var methods: [String] { Array(methodsByName.keys) }
        
        public let methodsByName:
            [String: (params: [(name: String, type: TypeDefinition)], result: TypeDefinition)]
        
        public init(network: Network.RuntimeApi, types: NetworkTypeRegistry) throws {
            self.name = network.name
            self.methodsByName = try Dictionary(
                uniqueKeysWithValues: network.methods.map { method in
                    let params = try method.inputs.map {
                        try ($0.name, types.get($0.type, .get()))
                    }
                    let result = try types.get(method.output, .get())
                    return (method.name, (params, result))
                }
            )
        }
        
        public func resolve(
            method name: String
        ) -> (params: [(name: String, type: TypeDefinition)], result: TypeDefinition)? {
            methodsByName[name]
        }
    }
}

public extension MetadataV15 {
    struct OuterEnums: OuterEnumsMetadata {
        public let callType: TypeDefinition
        public let eventType: TypeDefinition
        public let moduleErrorType: TypeDefinition
        
        public init(network: Network.OuterEnums,
                    types: NetworkTypeRegistry) throws
        {
            self.callType = try types.get(network.callEnumType, .get())
            self.eventType = try types.get(network.eventEnumType, .get())
            self.moduleErrorType = try types.get(network.moduleErrorEnumType, .get())
        }
    }
}
