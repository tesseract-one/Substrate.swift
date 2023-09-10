//
//  MetadataV14.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation

public final class MetadataV14: Metadata {
    public let version: UInt8
    public let extrinsic: ExtrinsicMetadata
    public var outerEnums: OuterEnumsMetadata? { nil }
    public var customTypes: Dictionary<String, (TypeDefinition, Data)>? { nil }
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { [] }
    
    public let types: NetworkTypeRegistry
    public let typesByName: [String: TypeDefinition]
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    
    public init(network: Network) throws {
        let types = try TypeRegistry.from(network: network.types).get()
        self.types = types
        self.version = network.version
        let byNamePairs = types.types.compactMap { kv in
            (kv.value.name, kv.value.strong)
        }
        self.typesByName = Dictionary(byNamePairs) { (l, r) in l }
        self.extrinsic = try Extrinsic(network: network.extrinsic, types: types)
        let pallets = try network.pallets.map { try Pallet(network: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.index, $0) })
    }
    
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
        try types.types.reduce(into: into) { r, e in try cb(&r, e.value.strong) }
    }
    
    @inlinable
    public func resolve(pallet index: UInt8) -> PalletMetadata? { palletsByIndex[index] }
    
    @inlinable
    public func resolve(pallet name: String) -> PalletMetadata? { palletsByName[name] }
    
    @inlinable
    public func resolve(api name: String) -> RuntimeApiMetadata? { nil }
}

public extension MetadataV14 {
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
        
        public init(network: Network.Pallet,
                    types: NetworkTypeRegistry) throws
        {
            self.name = network.name
            self.index = network.index
            self.call = try network.call.map { try types.get($0, .get()) }
            self.event = try network.event.map { try types.get($0, .get()) }
            self.error = try network.error.map { try types.get($0, .get()) }
            let calls = try self.call.map { try Self.variants(for: $0, .get()) }
            self.callNameByIdx = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.callByName = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0) })
            }
            let events = try self.event.flatMap { try Self.variants(for:$0, .get()) }
            self.eventNameByIdx = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.eventByName = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0) })
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
                    try ($0.name, Constant(network: $0, types: types))
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

public extension MetadataV14 {
    typealias StorageEntryModifier = Network.StorageEntryModifier
    typealias StorageHasher = Network.StorageHasher
    
    struct Storage: StorageMetadata {
        public let name: String
        public let modifier: StorageEntryModifier
        public let types: (keys: [(hasher: StorageHasher, type: TypeDefinition)],
                           value: TypeDefinition)
        public let defaultValue: Data
        public let documentation: [String]
        
        public init(network: Network.PalletStorageEntry,
                    pallet: String,
                    types: NetworkTypeRegistry) throws
        {
            self.name = network.name
            self.modifier = network.modifier
            self.defaultValue = network.defaultValue
            self.documentation = network.documentation
            var keys: [(StorageHasher, TypeDefinition)]
            var valueType: TypeDefinition
            switch network.type {
            case .plain(let vType):
                keys = []
                valueType = try types.get(vType, .get())
            case .map(hashers: let hashers, key: let kType, value: let vType):
                valueType = try types.get(vType, .get())
                switch hashers.count {
                case 0:
                    throw MetadataError.storageBadHashersCount(
                        expected: 1, got: 0, name: network.name,
                        pallet: pallet, info: .get()
                    )
                case 1:
                    keys = try [(hashers[0], types.get(kType, .get()))]
                default:
                    switch try types.get(kType, .get()).definition {
                    case .composite(fields: let fields):
                        guard hashers.count == fields.count else {
                            throw MetadataError.storageBadHashersCount(
                                expected: fields.count, got: hashers.count,
                                name: network.name, pallet: pallet, info: .get()
                            )
                        }
                        keys = zip(hashers, fields).map { hash, field in
                            (hash, *field.type)
                        }
                    default:
                        throw try MetadataError.storageNonCompositeKey(
                            name: network.name, pallet: pallet,
                            type: types.get(kType, .get()).strong, info: .get()
                        )
                    }
                }
            }
            self.types = (keys: keys, value: valueType)
        }
    }
}

public extension MetadataV14 {
    struct Constant: ConstantMetadata {
        public let name: String
        public let type: TypeDefinition
        public let value: Data
        public let documentation: [String]
        
        public init(network: Network.PalletConstant,
                    types: NetworkTypeRegistry) throws
        {
            self.name = network.name
            self.value = network.value
            self.documentation = network.documentation
            self.type = try types.get(network.type, .get())
        }
    }
}

public extension MetadataV14 {
    struct Extrinsic: ExtrinsicMetadata {
        public let version: UInt8
        public let type: TypeDefinition?
        public let extensions: [ExtrinsicExtensionMetadata]
        
        public var addressType: TypeDefinition? { nil }
        public var callType: TypeDefinition? { nil }
        public var signatureType: TypeDefinition? { nil }
        public var extraType: TypeDefinition? { nil }
        
        public init(network: Network.Extrinsic, types: NetworkTypeRegistry) throws {
            self.version = network.version
            self.type = try types.get(network.type, .get())
            self.extensions = try network.signedExtensions.map {
                try ExtrinsicExtension(network: $0, types: types)
            }
        }
    }
}

public extension MetadataV14 {
    struct ExtrinsicExtension: ExtrinsicExtensionMetadata {
        public let identifier: String
        public let type: TypeDefinition
        public let additionalSigned: TypeDefinition
        
        public init(network: Network.ExtrinsicSignedExtension,
                    types: NetworkTypeRegistry) throws
        {
            self.identifier = network.identifier
            self.type = try types.get(network.type, .get())
            self.additionalSigned = try types.get(network.additionalSigned, .get())
        }
    }
}
