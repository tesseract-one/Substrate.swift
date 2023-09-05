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
    public let customTypes: Dictionary<String, (NetworkType.Id, Data)>?
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { Array(apisByName.keys) }
    
    public let types: [NetworkType.Id: NetworkType]
    public let typesByPath: [String: NetworkType.Id] // joined by "."
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    public let apisByName: [String: RuntimeApi]!
    
    public init(network: Network) throws {
        let types = Dictionary<NetworkType.Id, NetworkType>(
            uniqueKeysWithValues: network.types.map { ($0.id, $0.type) }
        )
        self.version = network.version
        self.types = types
        let byPathPairs = network.types.compactMap { i in i.type.name.map { ($0, i.id) } }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
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
        self.customTypes = network.custom
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
    public func resolve(api name: String) -> RuntimeApiMetadata? { apisByName[name] }
}

public extension MetadataV15 {
    typealias Constant = MetadataV14.Constant
    typealias Storage = MetadataV14.Storage
    typealias ExtrinsicExtension = MetadataV14.ExtrinsicExtension
    typealias StorageEntryModifier = Network.StorageEntryModifier
    typealias StorageHasher = Network.StorageHasher
    
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
        
        public init(network: Network.Pallet, types: [NetworkType.Id: NetworkType]) throws {
            self.name = network.name
            self.index = network.index
            self.call = try network.call.map { try $0.i(types.get($0)) }
            self.event = try network.event.map { try $0.i(types.get($0)) }
            self.error = try network.error.map { try $0.i(types.get($0)) }
            let calls = try self.call.flatMap { try Self.variants(for: $0.type.definition, types: types) }
            self.callByName = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, ($0.index, $0.fields)) })
            }
            self.callNameByIdx = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            let events = try self.event.flatMap { try Self.variants(for:$0.type.definition, types: types) }
            self.eventByName = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, ($0.index, $0.fields)) })
            }
            self.eventNameByIdx = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.storageByName = try network.storage
                .flatMap {
                    try $0.entries.map {
                        try ($0.name, MetadataV14.Storage(network: $0, pallet: network.name, types: types))
                    }
                }.flatMap { Dictionary(uniqueKeysWithValues: $0) }
            self.constantByName = try Dictionary(
                uniqueKeysWithValues: network.constants.map {
                    ($0.name, try MetadataV14.Constant(network: $0, types: types))
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

public extension MetadataV15 {
    struct Extrinsic: ExtrinsicMetadata {
        public let version: UInt8
        public let addressType: NetworkType.Info?
        public let callType: NetworkType.Info?
        public let signatureType: NetworkType.Info?
        public let extraType: NetworkType.Info?
        public let extensions: [ExtrinsicExtensionMetadata]
        
        public var type: NetworkType.Info? { nil }
        
        public init(network: Network.Extrinsic, types: [NetworkType.Id: NetworkType]) throws {
            self.version = network.version
            self.addressType = try network.addressType.i(types.get(network.addressType))
            self.callType = try network.callType.i(types.get(network.callType))
            self.signatureType = try network.signatureType.i(types.get(network.signatureType))
            self.extraType = try network.extraType.i(types.get(network.extraType))
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
            [String: (params: [(name: String, type: NetworkType.Info)], result: NetworkType.Info)]
        
        public init(network: Network.RuntimeApi, types: [NetworkType.Id: NetworkType]) throws {
            self.name = network.name
            self.methodsByName = try Dictionary(
                uniqueKeysWithValues: network.methods.map { method in
                    let params = try method.inputs.map {
                        try ($0.name, $0.type.i(types.get($0.type)))
                    }
                    let result = try method.output.i(types.get(method.output))
                    return (method.name, (params, result))
                }
            )
        }
        
        public func resolve(
            method name: String
        ) -> (params: [(name: String, type: NetworkType.Info)], result: NetworkType.Info)? {
            methodsByName[name]
        }
    }
}

public extension MetadataV15 {
    struct OuterEnums: OuterEnumsMetadata {
        public let callType: NetworkType.Info
        public let eventType: NetworkType.Info
        public let moduleErrorType: NetworkType.Info
        
        public init(network: Network.OuterEnums, types: [NetworkType.Id: NetworkType]) throws {
            self.callType = try network.callEnumType.i(types.get(network.callEnumType))
            self.eventType = try network.eventEnumType.i(types.get(network.eventEnumType))
            self.moduleErrorType = try network.moduleErrorEnumType.i(types.get(network.moduleErrorEnumType))
        }
    }
}
