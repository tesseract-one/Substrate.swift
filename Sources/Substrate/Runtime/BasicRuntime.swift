//
//  File.swift
//  
//
//  Created by Yehor Popovych on 10/09/2023.
//

import Foundation
import ScaleCodec

open class BasicRuntime<RC: Config>: Runtime {
    public let config: RC
    public let addressFormat: SS58.AddressFormat
    public let metadata: any Metadata
    public let isBatchSupported: Bool
    public let types: DynamicTypes
    public let staticTypes: Synced<TypeRegistry<TypeDefinition.TypeId>>
    
    open var hasher: any FixedHasher { typedHasher }
    public let typedHasher: ST<RC>.Hasher
    
    open var extrinsicDecoder: any ExtrinsicDecoder { extrinsicManager }
    public let extrinsicManager: RC.TExtrinsicManager
    
    @inlinable
    public var dynamicCustomCoders: [ObjectIdentifier: any CustomDynamicCoder] {
        _dynamicCustomCoders
    }
    
    @inlinable
    public var dynamicRuntimeCustomCoders: [ObjectIdentifier: any RuntimeCustomDynamicCoder] {
        _dynamicRuntimeCustomCoders
    }
    
    open func encoder() -> any ScaleCodec.Encoder { config.encoder() }
    
    open func encoder(reservedCapacity: Int) -> any ScaleCodec.Encoder {
        config.encoder(reservedCapacity: reservedCapacity)
    }
    
    open func decoder(with data: Data) -> any ScaleCodec.Decoder {
        config.decoder(data: data)
    }
    
    public private(set) var _dynamicCustomCoders: [ObjectIdentifier: any CustomDynamicCoder]!
    public private(set) var _dynamicRuntimeCustomCoders: [ObjectIdentifier: any RuntimeCustomDynamicCoder]!
    
    public init(config: RC, metadata: any Metadata,
                types: DynamicTypes, addressFormat: SS58.AddressFormat) throws
    {
        self.config = config
        self.types = types
        self.metadata = metadata
        self.addressFormat = addressFormat
        self.typedHasher = try ST<RC>.Hasher(type: types.hasher.value)
        self.staticTypes = Synced(value: TypeRegistry())
        self.extrinsicManager = try config.extrinsicManager(types: types, metadata: metadata)
        if let bc = config as? any BatchSupportedConfig {
            self.isBatchSupported = bc.isBatchSupported(types: types, metadata: metadata)
        } else {
            self.isBatchSupported = false
        }
        let customCoders = try config.customCoders(types: types, metadata: metadata)
        self._dynamicCustomCoders = nil
        self._dynamicRuntimeCustomCoders = nil
        self._dynamicRuntimeCustomCoders = metadata.reduce(
            types: [ObjectIdentifier: any RuntimeCustomDynamicCoder]()
        ) { out, tdef in
            for coder in customCoders where coder.check(type: tdef, in: self) {
                out[tdef.objectId] = coder
            }
        }
        self._dynamicCustomCoders = _dynamicRuntimeCustomCoders.mapValues{$0.dynamicCoder(in: self)}
    }
    
    open func validate() throws {
        // Extrinsic and Extenstions
        try extrinsicManager.validate(runtime: self)
    }
}
