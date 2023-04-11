//
//  MetadateV14.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation


public class MetadataV14: Metadata {
    public let runtime: RuntimeMetadata
    public let extrinsic: ExtrinsicMetadata
    public let types: [RuntimeTypeId: RuntimeType]
    public let palletsByIndex: [UInt8: PalletMetadataV14]
    public let palletsByName: [String: PalletMetadataV14]
    
    public init(runtime: RuntimeMetadataV14) {
        let types = Dictionary<RuntimeTypeId, RuntimeType>(
            uniqueKeysWithValues: runtime.types.map { ($0.id, $0.type) }
        )
        self.runtime = runtime
        self.types = types
        self.extrinsic = ExtrinsicMetadataV14(runtime: runtime.extrinsic, types: types)
        let pallets = runtime.pallets.map { PalletMetadataV14(runtime: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.runtime.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.runtime.index, $0) })
    }
    
    @inlinable
    public func resolve(type id: RuntimeTypeId) -> RuntimeType? { types[id] }
    
    @inlinable
    public func resolve(type path: [String]) -> RuntimeTypeInfo? {
        types.first { $0.value.path == path }.flatMap { RuntimeTypeInfo(id: $0.key, type: $0.value) }
    }
    
    @inlinable
    public func resolve(pallet index: UInt8) -> PalletMetadata? { palletsByIndex[index] }
    
    @inlinable
    public func resolve(pallet name: String) -> PalletMetadata? { palletsByName[name] }
}

public class PalletMetadataV14: PalletMetadata {
    public let runtime: RuntimePalletMetadataV14
    //public weak var metadata: MetadataV14?
    
    @inlinable public var name: String { runtime.name }
    @inlinable public var index: UInt8 { runtime.index }
    public let call: RuntimeTypeInfo?
    public let event: RuntimeTypeInfo?
    
    public let callIdxByName: [String: UInt8]?
    public let callNameByIdx: [UInt8: String]?
    
    public let eventIdxByName: [String: UInt8]?
    public let eventNameByIdx: [UInt8: String]?
    
    public let storageByName: [String: StorageMetadataV14]?
    
    public init(runtime: RuntimePalletMetadataV14, types: [RuntimeTypeId: RuntimeType]) {
        self.runtime = runtime
        //self.metadata = metadata
        self.call = runtime.call.map { RuntimeTypeInfo(id: $0, type: types[$0]!) }
        self.event = runtime.event.map { RuntimeTypeInfo(id: $0, type: types[$0]!) }
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
        self.storageByName = runtime.storage
            .flatMap { $0.entries.map { ($0.name, StorageMetadataV14(runtime: $0, types: types)) } }
            .flatMap { Dictionary(uniqueKeysWithValues: $0) }
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
    public func storage(name: String) -> StorageMetadata? { storageByName?[name] }
    
    private static func variants(for def: RuntimeTypeDefinition) -> [RuntimeTypeVariantItem]? {
        switch def {
        case .variant(variants: let vars): return vars
        default: return nil
        }
    }
}

public class StorageMetadataV14: StorageMetadata {
    public let name: String
    public let modifier: StorageEntryModifier
    public let types: (keys: [(StorageHasher, RuntimeTypeInfo)], value: RuntimeTypeInfo)
    public let defaultValue: Data
    public let documentation: [String]
    
    public init(runtime: RuntimePalletStorageEntryMedatadaV14, types: [RuntimeTypeId: RuntimeType]) {
        self.name = runtime.name
        self.modifier = runtime.modifier
        self.defaultValue = runtime.defaultValue
        self.documentation = runtime.documentation
        switch runtime.type {
        case .plain(let vType):
            self.types = (keys: [], value: RuntimeTypeInfo(id: vType, type: types[vType]!))
        case .map(hashers: let hashers, key: let kType, value: let vType):
            var keys: [(StorageHasher, RuntimeTypeInfo)]
            switch types[kType]!.definition {
            case .composite(fields: let fields):
                keys = zip(hashers, fields).map { hash, field in
                    (hash, RuntimeTypeInfo(id: field.type, type: types[field.type]!))
                }
            case .tuple(components: let fields):
                keys = zip(hashers, fields).map { hash, field in
                    (hash, RuntimeTypeInfo(id: field, type: types[field]!))
                }
            default: fatalError("Unknown storage key type: \(types[kType]!)")
            }
            self.types = (keys: keys, value: RuntimeTypeInfo(id: vType, type: types[vType]!))
        }
    }
}

public class ExtrinsicMetadataV14: ExtrinsicMetadata {
    public let version: UInt8
    public let type: RuntimeTypeInfo
    public let extensions: [ExtrinsicExtensionMetadata]
    
    public init(runtime: RuntimeExtrinsicMetadataV14, types: [RuntimeTypeId: RuntimeType]) {
        self.version = runtime.version
        self.type = RuntimeTypeInfo(id: runtime.type, type: types[runtime.type]!)
        self.extensions = runtime.signedExtensions.map {
            ExtrinsicExtensionMetadataV14(runtime: $0, types: types)
        }
    }
}

public class ExtrinsicExtensionMetadataV14: ExtrinsicExtensionMetadata {
    public let identifier: String
    public let type: RuntimeTypeInfo
    public let additionalSigned: RuntimeTypeInfo
    
    public init(runtime: RuntimeExtrinsicSignedExtensionV14, types: [RuntimeTypeId: RuntimeType]) {
        self.identifier = runtime.identifier
        self.type = RuntimeTypeInfo(id: runtime.type, type: types[runtime.type]!)
        self.additionalSigned = RuntimeTypeInfo(id: runtime.additionalSigned,
                                                type: types[runtime.additionalSigned]!)
    }
}
