//
//  MetadataV14.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation

public final class MetadataV14: Metadata {
    public let extrinsic: ExtrinsicMetadata
    public var outerEnums: OuterEnumsMetadata? { nil }
    public var customTypes: Dictionary<String, (NetworkType.Id, Data)>? { nil }
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { [] }
    
    public let types: [NetworkType.Id: NetworkType]
    public let typesByPath: [String: NetworkType.Id] // joined by "."
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    
    public init(network: Network) throws {
        let types = Dictionary<NetworkType.Id, NetworkType>(
            uniqueKeysWithValues: network.types.map { ($0.id, $0.type) }
        )
        self.types = types
        let byPathPairs = network.types.compactMap { i in i.type.name.map { ($0, i.id) } }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
        self.extrinsic = try Extrinsic(network: network.extrinsic, types: types)
        let pallets = try network.pallets.map { try Pallet(network: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.index, $0) })
    }
    
    @inlinable
    public func resolve(type id: NetworkType.Id) -> NetworkType? { types[id] }
    
    @inlinable
    public func resolve(type path: String) -> NetworkType.Info? {
        typesByPath[path].flatMap{types[$0]?.i($0)}
    }
    
    @inlinable
    public func search(type cb: (String) -> Bool) -> NetworkType.Info? {
        typesByPath.first{cb($0.key)}.flatMap{types[$0.value]?.i($0.value)}
    }
    
    @inlinable public func reduce<R>(
        types into: R,
        _ cb: (inout R, NetworkType.Info) throws -> Void
    ) rethrows -> R {
        try types.reduce(into: into) { r, e in try cb(&r, e.key.i(e.value)) }
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
        public typealias FieldInfo = (field: NetworkType.Field, type: NetworkType)
        public typealias VariantInfo = (index: UInt8, fields: [FieldInfo])
        
        public let name: String
        public let index: UInt8
        public let call: NetworkType.Info?
        public let event: NetworkType.Info?
        public let error: NetworkType.Info?
        
        public let callNameByIdx: [UInt8: String]?
        public let callByName: [String: VariantInfo]?
        
        public let eventNameByIdx: [UInt8: String]?
        public let eventByName: [String: VariantInfo]?
        
        public let storageByName: [String: Storage]?
        public var storage: [String] {
            storageByName.map { Array($0.keys) } ?? []
        }
        
        public let constantByName: [String: Constant]
        public var constants: [String] {
            Array(constantByName.keys)
        }
        
        public init(network: Network.Pallet,
                    types: [NetworkType.Id: NetworkType]) throws {
            self.name = network.name
            self.index = network.index
            self.call = try network.call.map { try $0.i(types.get($0)) }
            self.event = try network.event.map { try $0.i(types.get($0)) }
            self.error = try network.error.map { try $0.i(types.get($0)) }
            let calls = try self.call.flatMap { try Self.variants(for: $0.type.definition, types: types) }
            self.callNameByIdx = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.callByName = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, ($0.index, $0.fields)) })
            }
            let events = try self.event.flatMap { try Self.variants(for:$0.type.definition, types: types) }
            self.eventNameByIdx = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.eventByName = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, ($0.index, $0.fields)) })
            }
            self.storageByName = try network.storage
                .flatMap {
                    try $0.entries.map {
                        try ($0.name, Storage(network: $0, pallet: network.name, types: types))
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
        public func callParams(name: String) -> [FieldInfo]? { callByName?[name]?.fields }
        
        @inlinable
        public func eventName(index: UInt8) -> String? { eventNameByIdx?[index] }
        
        @inlinable
        public func eventIndex(name: String) -> UInt8? { eventByName?[name]?.index }
        
        @inlinable
        public func eventParams(name: String) -> [FieldInfo]? { eventByName?[name]?.fields }
        
        @inlinable
        public func constant(name: String) -> ConstantMetadata? { constantByName[name] }
        
        @inlinable
        public func storage(name: String) -> StorageMetadata? { storageByName?[name] }
        
        private static func variants(
            for def: NetworkType.Definition, types: [NetworkType.Id: NetworkType]
        ) throws -> [(index: UInt8, name: String, fields: [FieldInfo])]? {
            switch def {
            case .variant(variants: let vars):
                return try vars.map {
                    try (index: $0.index, name: $0.name,
                         fields: $0.fields.map{try ($0, types.get($0.type))})
                }
            default: return nil
            }
        }
    }
}

public extension MetadataV14 {
    typealias StorageEntryModifier = Network.StorageEntryModifier
    typealias StorageHasher = Network.StorageHasher
    
    struct Storage: StorageMetadata {
        public let name: String
        public let modifier: StorageEntryModifier
        public let types: (keys: [(hasher: StorageHasher, type: NetworkType.Info)],
                           value: NetworkType.Info)
        public let defaultValue: Data
        public let documentation: [String]
        
        public init(network: Network.PalletStorageEntry,
                    pallet: String,
                    types: [NetworkType.Id: NetworkType]) throws
        {
            self.name = network.name
            self.modifier = network.modifier
            self.defaultValue = network.defaultValue
            self.documentation = network.documentation
            var keys: [(StorageHasher, NetworkType.Info)]
            var valueType: NetworkType.Id
            switch network.type {
            case .plain(let vType):
                keys = []
                valueType = vType
            case .map(hashers: let hashers, key: let kType, value: let vType):
                valueType = vType
                switch hashers.count {
                case 0:
                    throw MetadataError.storageBadHashersCount(expected: 1,
                                                               got: 0,
                                                               name: network.name,
                                                               pallet: pallet)
                case 1:
                    keys = try [(hashers[0], kType.i(types.get(kType)))]
                default:
                    switch types[kType]!.definition {
                    case .tuple(components: let fields): // DoubleMap / NMap
                        guard hashers.count == fields.count else {
                            throw MetadataError.storageBadHashersCount(expected: fields.count,
                                                                       got: hashers.count,
                                                                       name: network.name,
                                                                       pallet: pallet)
                        }
                        keys = try zip(hashers, fields).map { hash, field in
                            try (hash, field.i(types.get(field)))
                        }
                    case .composite(fields: let fields): // Array / Struct
                        guard hashers.count == fields.count else {
                            throw MetadataError.storageBadHashersCount(expected: fields.count,
                                                                       got: hashers.count,
                                                                       name: network.name,
                                                                       pallet: pallet)
                        }
                        keys = try zip(hashers, fields).map { hash, field in
                            try (hash, field.type.i(types.get(field.type)))
                        }
                    default:
                        throw try MetadataError.storageNonCompositeKey(
                            name: network.name, pallet: pallet,
                            type: kType.i(types.get(kType))
                        )
                    }
                }
            }
            self.types = try (keys: keys,
                              value: valueType.i(types.get(valueType)))
        }
    }
}

public extension MetadataV14 {
    struct Constant: ConstantMetadata {
        public let name: String
        public let type: NetworkType.Info
        public let value: Data
        public let documentation: [String]
        
        public init(network: Network.PalletConstant,
                    types: [NetworkType.Id: NetworkType]) throws
        {
            self.name = network.name
            self.value = network.value
            self.documentation = network.documentation
            self.type = try network.type.i(types.get(network.type))
        }
    }
}

public extension MetadataV14 {
    struct Extrinsic: ExtrinsicMetadata {
        public let version: UInt8
        public let type: NetworkType.Info?
        public let extensions: [ExtrinsicExtensionMetadata]
        
        public var addressType: NetworkType.Info? { nil }
        public var callType: NetworkType.Info? { nil }
        public var signatureType: NetworkType.Info? { nil }
        public var extraType: NetworkType.Info? { nil }
        
        public init(network: Network.Extrinsic, types: [NetworkType.Id: NetworkType]) throws {
            self.version = network.version
            self.type = try network.type.i(types.get(network.type))
            self.extensions = try network.signedExtensions.map {
                try ExtrinsicExtension(network: $0, types: types)
            }
        }
    }
}

public extension MetadataV14 {
    struct ExtrinsicExtension: ExtrinsicExtensionMetadata {
        public let identifier: String
        public let type: NetworkType.Info
        public let additionalSigned: NetworkType.Info
        
        public init(network: Network.ExtrinsicSignedExtension,
                    types: [NetworkType.Id: NetworkType]) throws
        {
            self.identifier = network.identifier
            self.type = try network.type.i(types.get(network.type))
            self.additionalSigned = try network.additionalSigned.i(types.get(network.additionalSigned))
        }
    }
}
