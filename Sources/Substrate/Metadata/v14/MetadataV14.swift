//
//  MetadataV14.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation

public class MetadataV14: Metadata {
    public let extrinsic: ExtrinsicMetadata
    public var outerEnums: OuterEnumsMetadata? { nil }
    public var customTypes: Dictionary<String, (RuntimeType.Id, Data)>? { nil }
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { [] }
    
    public let types: [RuntimeType.Id: RuntimeType]
    public let typesByPath: [String: RuntimeType.Info] // joined by "."
    public let palletsByIndex: [UInt8: Pallet]
    public let palletsByName: [String: Pallet]
    
    public init(network: Network) throws {
        let types = Dictionary<RuntimeType.Id, RuntimeType>(
            uniqueKeysWithValues: network.types.map { ($0.id, $0.type) }
        )
        self.types = types
        let byPathPairs = network.types.compactMap { i in i.type.name.map { ($0, i) } }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
        self.extrinsic = Extrinsic(network: network.extrinsic, types: types)
        let pallets = try network.pallets.map { try Pallet(network: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.index, $0) })
    }
    
    @inlinable
    public func resolve(type id: RuntimeType.Id) -> RuntimeType? { types[id] }
    
    @inlinable
    public func resolve(type path: [String]) -> RuntimeType.Info? {
        typesByPath[path.joined(separator: ".")]
    }
    
    @inlinable
    public func search(type cb: @escaping (String) -> Bool) -> RuntimeType.Info? {
        for (path, type) in typesByPath {
            if cb(path) { return type }
        }
        return nil
    }
    
    @inlinable
    public func resolve(pallet index: UInt8) -> PalletMetadata? { palletsByIndex[index] }
    
    @inlinable
    public func resolve(pallet name: String) -> PalletMetadata? { palletsByName[name] }
    
    @inlinable
    public func resolve(api name: String) -> RuntimeApiMetadata? { nil }
}

public extension MetadataV14 {
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
        
        public let storageByName: [String: Storage]?
        public var storage: [String] {
            storageByName.map { Array($0.keys) } ?? []
        }
        
        public let constantByName: [String: Constant]
        public var constants: [String] {
            Array(constantByName.keys)
        }
        
        public init(network: Network.Pallet,
                    types: [RuntimeType.Id: RuntimeType]) throws {
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
                        try ($0.name, Storage(network: $0, pallet: network.name, types: types))
                    }
                }.flatMap { Dictionary(uniqueKeysWithValues: $0) }
            self.constantByName = Dictionary(
                uniqueKeysWithValues: network.constants.map {
                    ($0.name, Constant(network: $0, types: types))
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

public extension MetadataV14 {
    typealias StorageEntryModifier = Network.StorageEntryModifier
    typealias StorageHasher = Network.StorageHasher
    
    class Storage: StorageMetadata {
        public let name: String
        public let modifier: StorageEntryModifier
        public let types: (keys: [(StorageHasher, RuntimeType.Info)],
                           value: RuntimeType.Info)
        public let defaultValue: Data
        public let documentation: [String]
        
        public init(network: Network.PalletStorageEntry,
                    pallet: String,
                    types: [RuntimeType.Id: RuntimeType]) throws
        {
            self.name = network.name
            self.modifier = network.modifier
            self.defaultValue = network.defaultValue
            self.documentation = network.documentation
            var keys: [(StorageHasher, RuntimeType.Info)]
            var valueType: RuntimeType.Id
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
                    keys = [(hashers[0], RuntimeType.Info(id: kType, type: types[kType]!))]
                default:
                    switch types[kType]!.definition {
                    case .tuple(components: let fields): // DoubleMap / NMap
                        guard hashers.count == fields.count else {
                            throw MetadataError.storageBadHashersCount(expected: fields.count,
                                                                       got: hashers.count,
                                                                       name: network.name,
                                                                       pallet: pallet)
                        }
                        keys = zip(hashers, fields).map { hash, field in
                            (hash, RuntimeType.Info(id: field, type: types[field]!))
                        }
                    case .composite(fields: let fields): // Array / Struct
                        guard hashers.count == fields.count else {
                            throw MetadataError.storageBadHashersCount(expected: fields.count,
                                                                       got: hashers.count,
                                                                       name: network.name,
                                                                       pallet: pallet)
                        }
                        keys = zip(hashers, fields).map { hash, field in
                            (hash, RuntimeType.Info(id: field.type, type: types[field.type]!))
                        }
                    default:
                        throw MetadataError.storageNonCompositeKey(
                            name: network.name, pallet: pallet,
                            type: RuntimeType.Info(id: kType, type: types[kType]!))
                    }
                }
            }
            self.types = (keys: keys,
                          value: RuntimeType.Info(id: valueType, type: types[valueType]!))
        }
    }
}

public extension MetadataV14 {
    class Constant: ConstantMetadata {
        public let name: String
        public let type: RuntimeType.Info
        public let value: Data
        public let documentation: [String]
        
        public init(network: Network.PalletConstant,
                    types: [RuntimeType.Id: RuntimeType])
        {
            self.name = network.name
            self.value = network.value
            self.documentation = network.documentation
            self.type = RuntimeType.Info(id: network.type, type: types[network.type]!)
        }
    }
}

public extension MetadataV14 {
    class Extrinsic: ExtrinsicMetadata {
        public let version: UInt8
        public let type: RuntimeType.Info
        public let extensions: [ExtrinsicExtensionMetadata]
        
        public var addressType: RuntimeType.Info? { nil }
        public var callType: RuntimeType.Info? { nil }
        public var signatureType: RuntimeType.Info? { nil }
        public var extraType: RuntimeType.Info? { nil }
        
        public init(network: Network.Extrinsic, types: [RuntimeType.Id: RuntimeType]) {
            self.version = network.version
            self.type = RuntimeType.Info(id: network.type, type: types[network.type]!)
            self.extensions = network.signedExtensions.map {
                ExtrinsicExtension(network: $0, types: types)
            }
        }
    }
}

public extension MetadataV14 {
    class ExtrinsicExtension: ExtrinsicExtensionMetadata {
        public let identifier: String
        public let type: RuntimeType.Info
        public let additionalSigned: RuntimeType.Info
        
        public init(network: Network.ExtrinsicSignedExtension,
                    types: [RuntimeType.Id: RuntimeType])
        {
            self.identifier = network.identifier
            self.type = RuntimeType.Info(id: network.type, type: types[network.type]!)
            self.additionalSigned = RuntimeType.Info(id: network.additionalSigned,
                                                     type: types[network.additionalSigned]!)
        }
    }
}
