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
    public func encoder() -> ScaleEncoder { config.encoder() }
    
    @inlinable
    public func decoder(with data: Data) -> ScaleDecoder { config.decoder(data: data) }
    
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
    }
    
    open func setSubstrate<S: SomeSubstrate<RC>>(substrate: S) throws {
        try self.extrinsicManager.setSubstrate(substrate: substrate)
    }
}


public struct LazyRuntimeTypes<RC: Config>: RuntimeTypes {
    private struct State {
        var blockHeader: Result<RuntimeTypeInfo, Error>?
        var extrinsic: Result<(addr: RuntimeTypeInfo, signature: RuntimeTypeInfo, extra: RuntimeTypeInfo), Error>?
        var dispatchInfo: Result<RuntimeTypeInfo, Error>?
        var dispatchError: Result<RuntimeTypeInfo, Error>?
        var feeDetails: Result<RuntimeTypeInfo, Error>?
        var transactionValidityError: Result<RuntimeTypeInfo, Error>?
    }
    
    private var _state: Synced<State>
    private var _config: RC
    private var _metadata: any Metadata
    
    public init(config: RC, metadata: any Metadata) {
        self._state = Synced(value: State())
        self._config = config
        self._metadata = metadata
    }
    
    public var blockHeader: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.blockHeader { return try res.get() }
            state.blockHeader = Result { try self._config.blockHeaderType(metadata: self._metadata) }
            return try state.blockHeader!.get()
        }
    }}
    
    public var address: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.extrinsic { return try res.get().addr }
            state.extrinsic = Result { try self._config.extrinsicTypes(metadata: self._metadata) }
            return try state.extrinsic!.get().addr
        }
    }}
    
    public var signature: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.extrinsic { return try res.get().signature }
            state.extrinsic = Result { try self._config.extrinsicTypes(metadata: self._metadata) }
            return try state.extrinsic!.get().signature
        }
    }}
    
    public var extrinsicExtra: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.extrinsic { return try res.get().extra }
            state.extrinsic = Result { try self._config.extrinsicTypes(metadata: self._metadata) }
            return try state.extrinsic!.get().extra
        }
    }}
    
    public var dispatchInfo: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.dispatchInfo { return try res.get() }
            state.dispatchInfo = Result { try self._config.dispatchInfoType(metadata: self._metadata) }
            return try state.dispatchInfo!.get()
        }
    }}
    
    public var dispatchError: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.dispatchError { return try res.get() }
            state.dispatchError = Result { try self._config.dispatchErrorType(metadata: self._metadata) }
            return try state.dispatchError!.get()
        }
    }}
    
    public var feeDetails: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.feeDetails { return try res.get() }
            state.feeDetails = Result { try self._config.feeDetailsType(metadata: self._metadata) }
            return try state.feeDetails!.get()
        }
    }}
    
    public var transactionValidityError: RuntimeTypeInfo { get throws {
        try _state.sync { state in
            if let res = state.transactionValidityError { return try res.get() }
            state.transactionValidityError = Result {
                try self._config.transactionValidityErrorType(metadata: self._metadata)
            }
            return try state.transactionValidityError!.get()
        }
    }}
}
