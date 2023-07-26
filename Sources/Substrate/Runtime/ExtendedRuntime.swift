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
    public let customCoders: [RuntimeCustomDynamicCoder]
    
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
    
    @inlinable
    public func custom(coder type: RuntimeType.Id) -> RuntimeCustomDynamicCoder? {
        try? customCoders.first { try $0.checkType(id: type, runtime: self) }
    }
    
    @inlinable
    public func queryInfoCall<C: Call>(
        extrinsic: Extrinsic<C, RC.TExtrinsicManager.TSignedExtra>
    ) throws -> any RuntimeCall<RC.TDispatchInfo> {
        var encoder = self.encoder()
        try extrinsicManager.encode(signed: extrinsic, in: &encoder)
        return try config.queryInfoCall(extrinsic: encoder.output, runtime: self)
    }
    
    @inlinable
    public func queryFeeDetailsCall<C: Call>(
        extrinsic: Extrinsic<C, RC.TExtrinsicManager.TSignedExtra>
    ) throws -> any RuntimeCall<RC.TFeeDetails> {
        var encoder = self.encoder()
        try extrinsicManager.encode(signed: extrinsic, in: &encoder)
        return try config.queryFeeDetailsCall(extrinsic: encoder.output, runtime: self)
    }
    
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
        self.customCoders = try config.customCoders()
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
        try create(account: RC.TAccountId.self, from: ss58)
    }
    
    @inlinable
    func account(pub: any PublicKey) throws -> RC.TAccountId {
        try pub.account(runtime: self)
    }
    
    @inlinable
    func account(raw: Data) throws -> RC.TAccountId {
        try create(account: RC.TAccountId.self, raw: raw)
    }
    
    @inlinable
    func address(account: RC.TAccountId) throws -> RC.TAddress {
        try account.address()
    }
    
    @inlinable
    func address(ss58: String) throws -> RC.TAddress {
        try account(ss58: ss58).address()
    }
    
    @inlinable
    func address(pub: any PublicKey) throws -> RC.TAddress {
        try pub.address(runtime: self)
    }
    
    @inlinable
    func hash(data: Data) throws -> RC.THasher.THash {
        try typedHasher.hash(data: data, runtime: self)
    }
}

public struct LazyRuntimeTypes<RC: Config>: RuntimeTypes {
    private struct State {
        var block: Result<RuntimeType.Info, Error>?
        var account: Result<RuntimeType.Info, Error>?
        var extrinsic: Result<(call: RuntimeType.Info, addr: RuntimeType.Info,
                               signature: RuntimeType.Info, extra: RuntimeType.Info), Error>?
        var event: Result<RuntimeType.Info, Error>?
        var hash: Result<RuntimeType.Info, Error>?
        var dispatchInfo: Result<RuntimeType.Info, Error>?
        var dispatchError: Result<RuntimeType.Info, Error>?
        var feeDetails: Result<RuntimeType.Info, Error>?
        var transactionValidityError: Result<RuntimeType.Info, Error>?
    }
    
    private var _state: Synced<State>
    private var _config: RC
    private var _metadata: any Metadata
    
    public init(config: RC, metadata: any Metadata) {
        self._state = Synced(value: State())
        self._config = config
        self._metadata = metadata
    }
    
    public var block: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.block { return try res.get() }
            state.block = Result { try self._config.blockType(metadata: self._metadata) }
            return try state.block!.get()
        }
    }}
    
    public var account: RuntimeType.Info { get throws {
        let address = try self.address
        return try _state.sync { state in
            if let res = state.account { return try res.get() }
            state.account = Result { try self._config.accountType(metadata: self._metadata, address: address) }
            return try state.account!.get()
        }
    }}
    
    public var call: RuntimeType.Info { get throws { try _extrinsic.call }}
    public var address: RuntimeType.Info { get throws { try _extrinsic.addr } }
    public var signature: RuntimeType.Info { get throws { try _extrinsic.signature }}
    public var extrinsicExtra: RuntimeType.Info { get throws { try _extrinsic.extra }}
    
    public var dispatchInfo: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.dispatchInfo { return try res.get() }
            state.dispatchInfo = Result { try self._config.dispatchInfoType(metadata: self._metadata) }
            return try state.dispatchInfo!.get()
        }
    }}
    
    public var dispatchError: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.dispatchError { return try res.get() }
            state.dispatchError = Result { try self._config.dispatchErrorType(metadata: self._metadata) }
            return try state.dispatchError!.get()
        }
    }}
    
    public var feeDetails: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.feeDetails { return try res.get() }
            state.feeDetails = Result { try self._config.feeDetailsType(metadata: self._metadata) }
            return try state.feeDetails!.get()
        }
    }}
    
    public var transactionValidityError: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.transactionValidityError { return try res.get() }
            state.transactionValidityError = Result {
                try self._config.transactionValidityErrorType(metadata: self._metadata)
            }
            return try state.transactionValidityError!.get()
        }
    }}
    
    public var event: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.event { return try res.get() }
            if let event = _metadata.enums?.eventType {
                state.event = .success(event)
            } else {
                state.event = Result { try _config.eventType(metadata: _metadata) }
            }
            return try state.event!.get()
        }
    }}
    
    public var hash: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.hash { return try res.get() }
            state.hash = Result {
                try self._config.hashType(metadata: self._metadata)
            }
            return try state.hash!.get()
        }
    }}
    
    private var _extrinsic: (call: RuntimeType.Info, addr: RuntimeType.Info,
                             signature: RuntimeType.Info, extra: RuntimeType.Info)
    { get throws {
        try _state.sync { state in
            if let res = state.extrinsic { return try res.get() }
            if let call = _metadata.extrinsic.callType,
               let addr = _metadata.extrinsic.addressType,
               let signature = _metadata.extrinsic.signatureType,
               let extra = _metadata.extrinsic.extraType
            {
                state.extrinsic = .success((call, addr, signature, extra))
            } else {
                state.extrinsic = Result { try self._config.extrinsicTypes(metadata: self._metadata) }
            }
            return try state.extrinsic!.get()
        }
    }}
}
