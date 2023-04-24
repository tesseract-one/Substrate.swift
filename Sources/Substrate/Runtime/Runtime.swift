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
    
    // configurations
    var blockHeaderType: RuntimeTypeInfo { get throws }
    var addressType: RuntimeTypeInfo { get throws }
    var signatureType: RuntimeTypeInfo { get throws }
    var extrinsicExtraType: RuntimeTypeInfo { get throws }
    
    func encoder() -> any ScaleEncoder
    func decoder(with data: Data) -> any ScaleDecoder
    
    func resolve(type id: RuntimeTypeId) -> RuntimeType?
    func resolve(type named: String) -> RuntimeTypeInfo?
    func resolve(type path: [String]) -> RuntimeTypeInfo?
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

public protocol RuntimeAware {
    var runtime: any Runtime { get }
}

public protocol RuntimeHolder: RuntimeAware {
    func setRuntime(runtime: any Runtime) throws
}

public extension Runtime {
    @inlinable
    func resolve(type id: RuntimeTypeId) -> RuntimeType? {
        metadata.resolve(type: id)
    }
    
    @inlinable
    func resolve(type named: String) -> RuntimeTypeInfo? {
        metadata.resolve(type: named)
    }
    
    @inlinable
    func resolve(type path: [String]) -> RuntimeTypeInfo? {
        metadata.resolve(type: path)
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
    public let config: RC
    public let metadata: any Metadata
    public let genesisHash: RC.THasher.THash
    public let version: RC.TRuntimeVersion
    public let properties: RC.TSystemProperties
    public var rpcMethods: Set<String> { get async throws { try await _rpcMethods.value } }
    
    public private(set) var extrinsicManager: RC.TExtrinsicManager
    
    public var blockHeaderType: RuntimeTypeInfo { get throws { try _blockHeaderType.value } }
    public var addressType: RuntimeTypeInfo { get throws { try _extrinsicTypes.value.addr } }
    public var signatureType: RuntimeTypeInfo { get throws { try _extrinsicTypes.value.signature } }
    public var extrinsicExtraType: RuntimeTypeInfo { get throws { try _extrinsicTypes.value.extra }}
    
    public let hasher: any Hasher
    @inlinable
    public var eventsStorageKey: any StorageKey<Data> { config.eventsStorageKey }
    
    @inlinable
    public var addressFormat: SS58.AddressFormat { properties.ss58Format }
    
    private let _blockHeaderType: LazyProperty<RuntimeTypeInfo>
    private let _extrinsicTypes: LazyProperty<
        (addr: RuntimeTypeInfo, signature: RuntimeTypeInfo, extra: RuntimeTypeInfo)
    >
    private var _rpcMethods: LazyAsyncProperty<Set<String>>!
    
    public init(config: RC, metadata: any Metadata,
                         genesisHash: RC.THasher.THash,
                         version: RC.TRuntimeVersion,
                         properties: RC.TSystemProperties) throws
    {
        self.config = config
        self.metadata = metadata
        self.genesisHash = genesisHash
        self.version = version
        self.properties = properties
        self.hasher = try config.hasher(metadata: metadata)
        self.extrinsicManager = try config.extrinsicManager()
        self._blockHeaderType = LazyProperty { try config.blockHeaderType(metadata: metadata) }
        self._extrinsicTypes = LazyProperty { try config.extrinsicTypes(metadata: metadata) }
        self._rpcMethods = nil
    }
    
    open func setSubstrate<S: SomeSubstrate<RC>>(substrate: S) throws {
        try self.extrinsicManager.setSubstrate(substrate: substrate)
        self._rpcMethods = LazyAsyncProperty { [unowned substrate] in
            try await substrate.rpc.rpc.methods().methods
        }
    }
}
