//
//  ExtendedRuntime.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec

open class ExtendedRuntime<RC: Config>: Runtime {
    public let config: RC
    public let metadata: any Metadata
    public let genesisHash: RC.THasher.THash
    public let version: RC.TRuntimeVersion
    public let properties: RC.TSystemProperties
    public let metadataHash: RC.THasher.THash?
    public let types: any RuntimeTypes
    public let isBatchSupported: Bool
    
    public private(set) var extrinsicManager: RC.TExtrinsicManager
    
    @inlinable
    public var hasher: any Hasher { typedHasher }
    
    @inlinable
    public var eventsStorageKey: any StorageKey<RC.TBlockEvents> {
        get throws { try config.eventsStorageKey(runtime: self) }
    }
    
    public let typedHasher: RC.THasher
    
    @inlinable
    public var addressFormat: SS58.AddressFormat { properties.ss58Format }
    
    @inlinable
    public func encoder() -> ScaleCodec.Encoder { config.encoder() }
    
    @inlinable
    public func decoder(with data: Data) -> ScaleCodec.Decoder { config.decoder(data: data) }
    
    public init(config: RC, metadata: any Metadata,
                metadataHash: RC.THasher.THash?,
                genesisHash: RC.THasher.THash,
                version: RC.TRuntimeVersion,
                properties: RC.TSystemProperties) throws
    {
        self.config = config
        self.metadata = metadata
        self.metadataHash = metadataHash
        self.genesisHash = genesisHash
        self.version = version
        self.properties = properties
        self.typedHasher = try config.hasher(metadata: metadata)
        self.extrinsicManager = try config.extrinsicManager()
        self.types = LazyRuntimeTypes(config: config, metadata: metadata)
        if let bc = config as? any BatchSupportedConfig {
            self.isBatchSupported = bc.isBatchSupported(metadata: metadata)
        } else {
            self.isBatchSupported = false
        }
    }
    
    open func setRootApi<A: RootApi<RC>>(api: A) throws {
        try self.extrinsicManager.setRootApi(api: api)
    }
}

public extension ExtendedRuntime {
    @inlinable
    func account(ss58: String) throws -> RC.TAccountId {
        try RC.TAccountId(from: ss58, runtime: self)
    }
    
    @inlinable
    func address(ss58: String) throws -> RC.TAddress {
        try account(ss58: ss58).address()
    }
    
    @inlinable
    func account(pub: any PublicKey) throws -> RC.TAccountId {
        try pub.account(runtime: self)
    }
    
    @inlinable
    func address(pub: any PublicKey) throws -> RC.TAddress {
        try pub.address(runtime: self)
    }
}
