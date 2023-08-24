//
//  MetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023.
//

import Foundation

public class MetadataV15: Metadata {
    public let extrinsic: ExtrinsicMetadata
    public let outerEnums: OuterEnumsMetadata?
    public let customTypes: Dictionary<String, (RuntimeType.Id, Data)>?
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { Array(apisByName.keys) }
    
    public let types: [RuntimeType.Id: RuntimeType]
    public let typesByPath: [String: RuntimeType.Info] // joined by "."
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    public let apisByName: [String: RuntimeApi]!
    
    public init(network: Network) throws {
        let types = Dictionary<RuntimeType.Id, RuntimeType>(
            uniqueKeysWithValues: network.types.map { ($0.id, $0.type) }
        )
        self.types = types
        let byPathPairs = network.types.compactMap { i in i.type.name.map { ($0, i) } }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
        self.extrinsic = MetadataV14.Extrinsic(network: network.extrinsic, types: types)
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
    public func resolve(type id: RuntimeType.Id) -> RuntimeType? { types[id] }
    
    @inlinable
    public func resolve(type path: [String]) -> RuntimeType.Info? {
        typesByPath[path.joined(separator: ".")]
    }
    
    @inlinable
    public func search(type cb: @escaping (String) -> Bool) -> RuntimeType.Info? {
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
    class Pallet: PalletMetadata {
        public let name: String
        public let index: UInt8
        public let call: RuntimeType.Info?
        public let event: RuntimeType.Info?
        public let error: RuntimeType.Info?
        
        public let callIdxByName: [String: UInt8]?
        public let callNameByIdx: [UInt8: String]?
        
        public let eventIdxByName: [String: UInt8]?
        public let eventNameByIdx: [UInt8: String]?
        
        public let callFields: [String: [RuntimeType.Field]]?
        
        public let storageByName: [String: MetadataV14.Storage]?
        public var storage: [String] {
            storageByName.map { Array($0.keys) } ?? []
        }
        
        public let constantByName: [String: MetadataV14.Constant]
        public var constants: [String] {
            Array(constantByName.keys)
        }
        
        public init(network: Network.Pallet, types: [RuntimeType.Id: RuntimeType]) throws {
            self.name = network.name
            self.index = network.index
            self.call = network.call.map { RuntimeType.Info(id: $0, type: types[$0]!) }
            self.event = network.event.map { RuntimeType.Info(id: $0, type: types[$0]!) }
            self.error = network.error.map { RuntimeType.Info(id: $0, type: types[$0]!) }
            let calls = self.call.flatMap { Self.variants(for: $0.type.definition) }
            self.callIdxByName = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0.index) })
            }
            self.callNameByIdx = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
            }
            self.callFields = calls.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0.fields) })
            }
            let events = self.event.flatMap { Self.variants(for:$0.type.definition) }
            self.eventIdxByName = events.map {
                Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0.index) })
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
        public func callIndex(name: String) -> UInt8? { callIdxByName?[name] }
        
        @inlinable
        public func callParams(name: String) -> [RuntimeType.Field]? { callFields?[name] }
        
        @inlinable
        public func eventName(index: UInt8) -> String? { eventNameByIdx?[index] }
        
        @inlinable
        public func eventIndex(name: String) -> UInt8? { eventIdxByName?[name] }
        
        @inlinable
        public func constant(name: String) -> ConstantMetadata? { constantByName[name] }
        
        @inlinable
        public func storage(name: String) -> StorageMetadata? { storageByName?[name] }
        
        private static func variants(
            for def: RuntimeType.Definition
        ) -> [RuntimeType.VariantItem]? {
            switch def {
            case .variant(variants: let vars): return vars
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
            [String: (params: [(String, RuntimeType.Info)], result: RuntimeType.Info)]
        
        public init(network: Network.RuntimeApi, types: [RuntimeType.Id: RuntimeType]) {
            self.name = network.name
            self.methodsByName = Dictionary(
                uniqueKeysWithValues: network.methods.map { method in
                    let params = method.inputs.map {
                        ($0.name, RuntimeType.Info(id: $0.type, type: types[$0.type]!))
                    }
                    let result = RuntimeType.Info(id: method.output, type: types[method.output]!)
                    return (method.name, (params, result))
                }
            )
        }
        
        public func resolve(
            method name: String
        ) -> (params: [(String, RuntimeType.Info)], result: RuntimeType.Info)? {
            methodsByName[name]
        }
    }
}

public extension MetadataV15 {
    struct OuterEnums: OuterEnumsMetadata {
        public let callType: RuntimeType.Info
        public let eventType: RuntimeType.Info
        public let moduleErrorType: RuntimeType.Info
        
        public init(network: Network.OuterEnums, types: [RuntimeType.Id: RuntimeType]) {
            self.callType = RuntimeType.Info(id: network.callEnumType,
                                             type: types[network.callEnumType]!)
            self.eventType = RuntimeType.Info(id: network.eventEnumType,
                                              type: types[network.eventEnumType]!)
            self.moduleErrorType = RuntimeType.Info(id: network.moduleErrorEnumType,
                                                    type: types[network.moduleErrorEnumType]!)
        }
    }
}
