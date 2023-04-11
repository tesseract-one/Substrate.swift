//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import ScaleCodec

public protocol Runtime: AnyObject {
    var addressFormat: SS58.AddressFormat { get }
    var metadata: any Metadata { get }
    var hasher: any Hasher { get }
    var extrinsicDecoder: any ExtrinsicDecoder { get }
    var blockHeaderType: RuntimeTypeInfo? { get }
    
    func encoder() -> any ScaleEncoder
    func decoder(with data: Data) -> any ScaleDecoder
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
//    func resolve(type path: String) -> RuntimeTypeInfo?
    func resolve(palletName index: UInt8) -> String?
    func resolve(palletIndex name: String) -> UInt8?
        
    // Calls
    func resolve(callType pallet: UInt8) -> RuntimeTypeInfo?
    func resolve(callType pallet: String) -> RuntimeTypeInfo?
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    
    // Events
    func resolve(eventType pallet: UInt8) -> RuntimeTypeInfo?
    func resolve(eventType pallet: String) -> RuntimeTypeInfo?
    func resolve(eventName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)?
    func resolve(eventIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)?
    
    // Storage
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(StorageHasher, RuntimeTypeId)], value: RuntimeTypeId)?
}

public protocol RuntimeOwner {
    var runtime: any Runtime { get set }
}

public extension Runtime {
    @inlinable
    func resolve(type id: RuntimeTypeId) -> RuntimeType? {
        metadata.resolve(type: id)
    }
    
    @inlinable
    func resolve(callType pallet: UInt8) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.call
    }
    
    @inlinable
    func resolve(callType pallet: String) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.call
    }
    
    @inlinable
    func resolve(callName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.callName(index: index).map { (pallet.name, $0) }
        }
    }
    
    @inlinable
    func resolve(callIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.callIndex(name: name).map { (pallet.index, $0) }
        }
    }
    
    @inlinable
    func resolve(eventType pallet: UInt8) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.event
    }
    
    @inlinable
    func resolve(eventType pallet: String) -> RuntimeTypeInfo? {
        metadata.resolve(pallet: pallet)?.event
    }
    
    @inlinable
    func resolve(eventName index: UInt8, pallet: UInt8) -> (pallet: String, name: String)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.eventName(index: index).map { (pallet.name, $0) }
        }
    }
    
    @inlinable
    func resolve(eventIndex name: String, pallet: String) -> (pallet: UInt8, index: UInt8)? {
        metadata.resolve(pallet: pallet).flatMap { pallet in
            pallet.eventIndex(name: name).map { (pallet.index, $0) }
        }
    }
    
    @inlinable
    func resolve(palletName index: UInt8) -> String? {
        metadata.resolve(pallet: index)?.name
    }
    
    @inlinable
    func resolve(palletIndex name: String) -> UInt8? {
        metadata.resolve(pallet: name)?.index
    }
    
    @inlinable
    func resolve(
        storage name: String, pallet: String
    ) -> (keys: [(StorageHasher, RuntimeTypeId)], value: RuntimeTypeId)? {
        metadata.resolve(pallet: pallet)?.storage(name: name).flatMap {
            let (keys, value) = $0.types
            return (keys.map { ($0.0, $0.1.id) }, value.id)
        }
    }
    
    @inlinable
    func encoder() -> ScaleEncoder { SCALE.default.encoder() }
    
    @inlinable
    func decoder(with data: Data) -> ScaleDecoder { SCALE.default.decoder(data: data) }
}

open class ExtendedRuntime<RC: RuntimeConfig>: Runtime {
    public let metadata: any Metadata
    public let eventsStorageKey: any StorageKey<Data>
    public let hasher: any Hasher
    public let blockHeaderType: RuntimeTypeInfo?
    
    public let genesisHash: RC.THasher.THash
    public let version: RC.TRuntimeVersion
    public let properties: RC.TSystemProperties
    public private(set) var extrinsicManager: RC.TExtrinsicManager
    
    @inlinable
    public var addressFormat: SS58.AddressFormat { properties.ss58Format }
    @inlinable
    public var extrinsicDecoder: any ExtrinsicDecoder { extrinsicManager }
    
    public init(config: RC, metadata: any Metadata,
                         genesisHash: RC.THasher.THash,
                         version: RC.TRuntimeVersion,
                         properties: RC.TSystemProperties) throws
    {
        self.metadata = metadata
        self.genesisHash = genesisHash
        self.version = version
        self.properties = properties
        self.eventsStorageKey = config.eventsStorageKey
        self.blockHeaderType = try config.blockHeaderType(metadata: metadata)
        self.hasher = try config.hasher(metadata: metadata)
        self.extrinsicManager = try config.extrinsicManager()
    }
    
    open func setSubstrate<S: AnySubstrate<RC>>(substrate: S) throws {
        try self.extrinsicManager.setSubstrate(substrate: substrate)
    }
}
//
//public protocol ExtendedRuntime<RC>: Runtime {
//    associatedtype RC: RuntimeConfig
//    
//    var genesisHash: RC.THasher.THash { get }
//    var runtimeVersion: RC.TRuntimeVersion { get }
//    var properties: RC.TSystemProperties { get }
//    var eventsStorageKey: any StorageKey<Data> { get }
//    var extrinsicManager: RC.TExtrinsicManager { get }
//    
//    init(config: RC, metadata: any Metadata,
//         genesisHash: RC.THasher.THash,
//         runtimeVersion: RC.TRuntimeVersion,
//         properties: RC.TSystemProperties) throws
//    
//    func setSubstrate<S: AnySubstrate<RC>>(substrate: S) throws
//}
//
//public extension ExtendedRuntime {
//    @inlinable
//    var addressFormat: SS58.AddressFormat { properties.ss58Format }
//    @inlinable
//    var extrinsicDecoder: any ExtrinsicDecoder { extrinsicManager }
//}
//
//open class SubstrateRuntime<RC: RuntimeConfig>: ExtendedRuntime {
//    public typealias RC = RC
//    
//    public let metadata: any Metadata
//    public let eventsStorageKey: any StorageKey<Data>
//    public let hasher: any Hasher
//    public let genesisHash: RC.THasher.THash
//    public let runtimeVersion: RC.TRuntimeVersion
//    public let properties: RC.TSystemProperties
//    public private(set) var extrinsicManager: RC.TExtrinsicManager
//    
//    public var extrinsicDecoder: ExtrinsicDecoder { extrinsicManager }
//    
//    required public init(config: RC, metadata: any Metadata,
//                         genesisHash: RC.THasher.THash,
//                         runtimeVersion: RC.TRuntimeVersion,
//                         properties: RC.TSystemProperties) throws
//    {
//        self.metadata = metadata
//        self.genesisHash = genesisHash
//        self.runtimeVersion = runtimeVersion
//        self.properties = properties
//        self.eventsStorageKey = config.eventsStorageKey
//        self.hasher = try config.hasher(metadata: metadata)
//        self.extrinsicManager = try config.extrinsicManager()
//    }
//    
//    public func setSubstrate<S: AnySubstrate<RC>>(substrate: S) throws {
//        try self.extrinsicManager.setSubstrate(substrate: substrate)
//    }
//}
