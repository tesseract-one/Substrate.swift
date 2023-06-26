//
//  MetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023.
//

import Foundation

public class MetadataV15: Metadata {
    public let extrinsic: ExtrinsicMetadata
    public var enums: OuterEnumsMetadata? { nil }
    public var pallets: [String] { Array(palletsByName.keys) }
    public var apis: [String] { Array(apisByName.keys) }
    
    public let types: [RuntimeTypeId: RuntimeType]
    public let typesByPath: [String: RuntimeTypeInfo] // joined by "."
    public let palletsByIndex: [UInt8: PalletMetadataV15]
    public let palletsByName: [String: PalletMetadataV15]
    public let apisByName: [String: RuntimeApiMetadataV15]!
    
    public init(runtime: RuntimeMetadataV15) throws {
        let types = Dictionary<RuntimeTypeId, RuntimeType>(
            uniqueKeysWithValues: runtime.types.map { ($0.id, $0.type) }
        )
        self.types = types
        let byPathPairs = runtime.types.compactMap {
            $0.type.path.count > 0 ? ($0.type.path.joined(separator: "."), $0) : nil
        }
        self.typesByPath = Dictionary(byPathPairs) { (l, r) in l }
        self.extrinsic = ExtrinsicMetadataV14(runtime: runtime.extrinsic, types: types)
        let pallets = try runtime.pallets.map { try PalletMetadataV15(runtime: $0, types: types) }
        self.palletsByName = Dictionary(uniqueKeysWithValues: pallets.map { ($0.name, $0) })
        self.palletsByIndex = Dictionary(uniqueKeysWithValues: pallets.map { ($0.index, $0) })
        self.apisByName = Dictionary(
            uniqueKeysWithValues: runtime.apis.map {
                ($0.name, RuntimeApiMetadataV15(runtime: $0, types: types))
            }
        )
    }
    
    @inlinable
    public func resolve(type id: RuntimeTypeId) -> RuntimeType? { types[id] }
    
    @inlinable
    public func resolve(type path: [String]) -> RuntimeTypeInfo? {
        typesByPath[path.joined(separator: ".")]
    }
    
    @inlinable
    public func search(type cb: @escaping ([String]) -> Bool) -> RuntimeTypeInfo? {
        for type in typesByPath.values {
            if cb(type.type.path) {
                return type
            }
        }
        return nil
    }
    
    @inlinable
    public func resolve(pallet index: UInt8) -> PalletMetadata? { palletsByIndex[index] }
    
    @inlinable
    public func resolve(pallet name: String) -> PalletMetadata? { palletsByName[name] }
    
    @inlinable
    public func resolve(api name: String) -> RuntimeApiMetadata? { apisByName[name] }
}

public class PalletMetadataV15: PalletMetadata {
    public let name: String
    public let index: UInt8
    public let call: RuntimeTypeInfo?
    public let event: RuntimeTypeInfo?
    
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
    
    public init(runtime: RuntimePalletMetadataV15, types: [RuntimeTypeId: RuntimeType]) throws {
        self.name = runtime.name
        self.index = runtime.index
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
    
    private static func variants(for def: RuntimeTypeDefinition) -> [RuntimeTypeVariantItem]? {
        switch def {
        case .variant(variants: let vars): return vars
        default: return nil
        }
    }
}

public struct RuntimeApiMetadataV15: RuntimeApiMetadata {
    public let name: String
    public var methods: [String] { Array(methodsByName.keys) }
    
    public let methodsByName: [String: (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)]
    
    public init(runtime: RuntimeRuntimeApiMetadataV15, types: [RuntimeTypeId: RuntimeType]) {
        self.name = runtime.name
        self.methodsByName = Dictionary(
            uniqueKeysWithValues: runtime.methods.map { method in
                let params = method.inputs.map {
                    ($0.name, RuntimeTypeInfo(id: $0.type, type: types[$0.type]!))
                }
                let result = RuntimeTypeInfo(id: method.output, type: types[method.output]!)
                return (method.name, (params, result))
            }
        )
    }
    
    public func resolve(method name: String) -> (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)? {
        methodsByName[name]
    }
}
