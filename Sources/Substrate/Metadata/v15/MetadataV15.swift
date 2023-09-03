//
//  MetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023.
//

import Foundation

public final class MetadataV15: Metadata {
    public let extrinsic: ExtrinsicMetadata
    public let outerEnums: OuterEnumsMetadata?
    public let customTypes: Dictionary<String, (NetworkType.Id, Data)>?
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { Array(apisByName.keys) }
    
    public let types: [NetworkType.Id: NetworkType]
    public let typesByPath: [String: NetworkType.Info] // joined by "."
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    public let apisByName: [String: RuntimeApi]!
    
    public init(network: Network) throws {
        let types = Dictionary<NetworkType.Id, NetworkType>(
            uniqueKeysWithValues: network.types.map { ($0.id, $0.type) }
        )
        self.types = types
        let byPathPairs = network.types.compactMap { i in i.type.name.map { ($0, i) } }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
        self.extrinsic = Extrinsic(network: network.extrinsic, types: types)
        let pallets = try network.pallets.map { try Pallet(network: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.index, $0) })
        self.apisByName = Dictionary(
            uniqueKeysWithValues: network.apis.map {
                ($0.name, RuntimeApi(network: $0, types: types))
            }
        )
        self.outerEnums = network.outerEnums.map { OuterEnums(network: $0, types: types) }
        self.customTypes = network.custom
    }
    
    @inlinable
    public func resolve(type id: NetworkType.Id) -> NetworkType? { types[id] }
    
    @inlinable
    public func resolve(type path: [String]) -> NetworkType.Info? {
        typesByPath[path.joined(separator: ".")]
    }
    
    @inlinable
    public func search(type cb: (String) -> Bool) -> NetworkType.Info? {
        typesByPath.first { cb($0.key) }?.value
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
    typealias Extrinsic = MetadataV14.Extrinsic
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
            self.call = network.call.map { NetworkType.Info(id: $0, type: types[$0]!) }
            self.event = network.event.map { NetworkType.Info(id: $0, type: types[$0]!) }
            self.error = network.error.map { NetworkType.Info(id: $0, type: types[$0]!) }
            let calls = self.call.flatMap { Self.variants(for: $0.type.definition, types: types) }
            self.callByName = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, ($0.index, $0.fields)) })
            }
            self.callNameByIdx = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            let events = self.event.flatMap { Self.variants(for:$0.type.definition, types: types) }
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
            self.constantByName = Dictionary(
                uniqueKeysWithValues: network.constants.map {
                    ($0.name, MetadataV14.Constant(network: $0, types: types))
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
        ) -> [(index: UInt8, name: String, fields: [FieldInfo])]? {
            switch def {
            case .variant(variants: let vars):
                return vars.map {
                    (index: $0.index, name: $0.name,
                     fields: $0.fields.map{($0, types[$0.type]!)})
                }
            default: return nil
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
        
        public init(network: Network.RuntimeApi, types: [NetworkType.Id: NetworkType]) {
            self.name = network.name
            self.methodsByName = Dictionary(
                uniqueKeysWithValues: network.methods.map { method in
                    let params = method.inputs.map {
                        ($0.name, NetworkType.Info(id: $0.type, type: types[$0.type]!))
                    }
                    let result = NetworkType.Info(id: method.output, type: types[method.output]!)
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
        
        public init(network: Network.OuterEnums, types: [NetworkType.Id: NetworkType]) {
            self.callType = NetworkType.Info(id: network.callEnumType,
                                             type: types[network.callEnumType]!)
            self.eventType = NetworkType.Info(id: network.eventEnumType,
                                              type: types[network.eventEnumType]!)
            self.moduleErrorType = NetworkType.Info(id: network.moduleErrorEnumType,
                                                    type: types[network.moduleErrorEnumType]!)
        }
    }
}
