//
//  MetadateV14.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation


public class MetadataV14: Metadata {
    public let extrinsic: ExtrinsicMetadata
    public var enums: OuterEnumsMetadata? { nil }
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { [] }
    
    public let types: [RuntimeType.Id: RuntimeType]
    public let typesByPath: [String: RuntimeType.Info] // joined by "."
    public let palletsByIndex: [UInt8: PalletMetadataV14]
    public let palletsByName: [String: PalletMetadataV14]
    
    public init(runtime: RuntimeMetadataV14) throws {
        let types = Dictionary<RuntimeType.Id, RuntimeType>(
            uniqueKeysWithValues: runtime.types.map { ($0.id, $0.type) }
        )
        self.types = types
        let byPathPairs = runtime.types.compactMap { i in i.type.name.map { ($0, i) } }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
        self.extrinsic = ExtrinsicMetadataV14(runtime: runtime.extrinsic, types: types)
        let pallets = try runtime.pallets.map { try PalletMetadataV14(runtime: $0, types: types) }
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

public class PalletMetadataV14: PalletMetadata {
    public let name: String
    public let index: UInt8
    public let call: RuntimeType.Info?
    public let event: RuntimeType.Info?
    
    public let callIdxByName: [String: UInt8]?
    public let callNameByIdx: [UInt8: String]?
    
    public let eventIdxByName: [String: UInt8]?
    public let eventNameByIdx: [UInt8: String]?
    
    public let storageByName: [String: StorageMetadataV14]?
    public var storage: [String] {
        storageByName.map { Array($0.keys) } ?? []
    }
    
    public let constantByName: [String: ConstantMetadataV14]
    public var constants: [String] {
        Array(constantByName.keys)
    }
    
    public init(runtime: RuntimePalletMetadataV14, types: [RuntimeType.Id: RuntimeType]) throws {
        self.name = runtime.name
        self.index = runtime.index
        self.call = runtime.call.map { RuntimeType.Info(id: $0, type: types[$0]!) }
        self.event = runtime.event.map { RuntimeType.Info(id: $0, type: types[$0]!) }
        let calls = self.call.flatMap { Self.variants(for: $0.type.definition) }
        self.callIdxByName = calls.map {
            Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0.index) })
        }
        self.callNameByIdx = calls.map {
            Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
        }
        let events = self.event.flatMap { Self.variants(for:$0.type.definition) }
        self.eventIdxByName = events.map {
            Dictionary(uniqueKeysWithValues: $0.map { ($0.name, $0.index) })
        }
        self.eventNameByIdx = events.map {
            Dictionary(uniqueKeysWithValues: $0.map { ($0.index, $0.name) })
        }
        self.storageByName = try runtime.storage
            .flatMap {
                try $0.entries.map {
                    try ($0.name, StorageMetadataV14(runtime: $0, pallet: runtime.name, types: types))
                }
            }.flatMap { Dictionary(uniqueKeysWithValues: $0) }
        self.constantByName = Dictionary(
            uniqueKeysWithValues: runtime.constants.map {
                ($0.name, ConstantMetadataV14(runtime: $0, types: types))
            }
        )
    }
    
    @inlinable
    public func callName(index: UInt8) -> String? { callNameByIdx?[index] }
    
    @inlinable
    public func callIndex(name: String) -> UInt8? { callIdxByName?[name] }
    
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

public class StorageMetadataV14: StorageMetadata {
    public let name: String
    public let modifier: StorageEntryModifier
    public let types:
        (keys: [(StorageHasher, RuntimeType.Info)], value: RuntimeType.Info)
    public let defaultValue: Data
    public let documentation: [String]
    
    public init(runtime: RuntimePalletStorageEntryMedatadaV14,
                pallet: String,
                types: [RuntimeType.Id: RuntimeType]) throws
    {
        self.name = runtime.name
        self.modifier = runtime.modifier
        self.defaultValue = runtime.defaultValue
        self.documentation = runtime.documentation
        var keys: [(StorageHasher, RuntimeType.Info)]
        var valueType: RuntimeType.Id
        switch runtime.type {
        case .plain(let vType):
            keys = []
            valueType = vType
        case .map(hashers: let hashers, key: let kType, value: let vType):
            valueType = vType
            switch hashers.count {
            case 0:
                throw MetadataError.storageBadHashersCount(expected: 1,
                                                           got: 0,
                                                           name: runtime.name,
                                                           pallet: pallet)
            case 1:
                keys = [(hashers[0], RuntimeType.Info(id: kType, type: types[kType]!))]
            default:
                switch types[kType]!.definition {
                case .tuple(components: let fields): // DoubleMap / NMap
                    guard hashers.count == fields.count else {
                        throw MetadataError.storageBadHashersCount(expected: fields.count,
                                                                   got: hashers.count,
                                                                   name: runtime.name,
                                                                   pallet: pallet)
                    }
                    keys = zip(hashers, fields).map { hash, field in
                        (hash, RuntimeType.Info(id: field, type: types[field]!))
                    }
                case .composite(fields: let fields): // Array / Struct
                    guard hashers.count == fields.count else {
                        throw MetadataError.storageBadHashersCount(expected: fields.count,
                                                                   got: hashers.count,
                                                                   name: runtime.name,
                                                                   pallet: pallet)
                    }
                    keys = zip(hashers, fields).map { hash, field in
                        (hash, RuntimeType.Info(id: field.type, type: types[field.type]!))
                    }
                default:
                    throw MetadataError.storageNonCompositeKey(
                        name: runtime.name, pallet: pallet,
                        type: RuntimeType.Info(id: kType, type: types[kType]!))
                }
            }
        }
        self.types = (keys: keys,
                      value: RuntimeType.Info(id: valueType, type: types[valueType]!))
    }
}

public class ConstantMetadataV14: ConstantMetadata {
    public let name: String
    public let type: RuntimeType.Info
    public let value: Data
    public let documentation: [String]
    
    public init(runtime: RuntimePalletConstantMetadataV14,
                types: [RuntimeType.Id: RuntimeType])
    {
        self.name = runtime.name
        self.value = runtime.value
        self.documentation = runtime.documentation
        self.type = RuntimeType.Info(id: runtime.type, type: types[runtime.type]!)
    }
}

public class ExtrinsicMetadataV14: ExtrinsicMetadata {
    public let version: UInt8
    public let type: RuntimeType.Info
    public let extensions: [ExtrinsicExtensionMetadata]
    
    public var addressType: RuntimeType.Info? { nil }
    public var callType: RuntimeType.Info? { nil }
    public var signatureType: RuntimeType.Info? { nil }
    public var extraType: RuntimeType.Info? { nil }
    
    public init(runtime: RuntimeExtrinsicMetadataV14, types: [RuntimeType.Id: RuntimeType]) {
        self.version = runtime.version
        self.type = RuntimeType.Info(id: runtime.type, type: types[runtime.type]!)
        self.extensions = runtime.signedExtensions.map {
            ExtrinsicExtensionMetadataV14(runtime: $0, types: types)
        }
    }
}

public class ExtrinsicExtensionMetadataV14: ExtrinsicExtensionMetadata {
    public let identifier: String
    public let type: RuntimeType.Info
    public let additionalSigned: RuntimeType.Info
    
    public init(runtime: RuntimeExtrinsicSignedExtensionV14,
                types: [RuntimeType.Id: RuntimeType])
    {
        self.identifier = runtime.identifier
        self.type = RuntimeType.Info(id: runtime.type, type: types[runtime.type]!)
        self.additionalSigned = RuntimeType.Info(id: runtime.additionalSigned,
                                                 type: types[runtime.additionalSigned]!)
    }
}
