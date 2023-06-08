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
    
    public private(set) var extrinsicManager: RC.TExtrinsicManager
    
    public var blockHeaderType: RuntimeTypeInfo { get throws { try _blockHeaderType.value } }
    public var addressType: RuntimeTypeInfo { get throws { try _extrinsicTypes.value.addr } }
    public var signatureType: RuntimeTypeInfo { get throws { try _extrinsicTypes.value.signature } }
    public var extrinsicExtraType: RuntimeTypeInfo { get throws { try _extrinsicTypes.value.extra }}
    
    @inlinable
    public var hasher: any Hasher { typedHasher }
    
    public let eventsStorageKey: any StorageKey<RC.TBlockEvents>
    public let typedHasher: RC.THasher
    
    @inlinable
    public var addressFormat: SS58.AddressFormat { properties.ss58Format }
    
    @inlinable
    public func encoder() -> ScaleEncoder { config.encoder() }
    
    @inlinable
    public func decoder(with data: Data) -> ScaleDecoder { config.decoder(data: data) }
    
    private let _blockHeaderType: LazyProperty<RuntimeTypeInfo>
    private let _extrinsicTypes: LazyProperty<
        (addr: RuntimeTypeInfo, signature: RuntimeTypeInfo, extra: RuntimeTypeInfo)
    >
    
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
        self._blockHeaderType = LazyProperty { try config.blockHeaderType(metadata: metadata) }
        self._extrinsicTypes = LazyProperty { try config.extrinsicTypes(metadata: metadata) }
        self.eventsStorageKey = try config.eventsStorageKey(metadata: metadata)
    }
    
    open func setSubstrate<S: SomeSubstrate<RC>>(substrate: S) throws {
        try self.extrinsicManager.setSubstrate(substrate: substrate)
    }
}
