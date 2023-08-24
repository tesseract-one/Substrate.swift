//
//  ExtendedRuntime.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import ContextCodable

public protocol SystemProperties: ContextDecodable where DecodingContext == (any Metadata) {
    var ss58Format: SS58.AddressFormat? { get }
}

public protocol RuntimeVersion: ContextDecodable where DecodingContext == (any Metadata) {
    associatedtype TVersion: ConfigUnsignedInteger
    
    var specVersion: TVersion { get }
    var transactionVersion: TVersion { get }
}

open class ExtendedRuntime<RC: Config>: Runtime {
    public let config: RC
    public let metadata: any Metadata
    public let genesisHash: ST<RC>.Hash
    public let version: ST<RC>.RuntimeVersion
    public let properties: ST<RC>.SystemProperties
    public let metadataHash: ST<RC>.Hash?
    public let types: any RuntimeTypes
    public let isBatchSupported: Bool
    public let customCoders: [RuntimeCustomDynamicCoder]
    
    public private(set) var extrinsicManager: RC.TExtrinsicManager
    
    @inlinable
    public var extrinsicDecoder: ExtrinsicDecoder { extrinsicManager }
    
    @inlinable
    public var hasher: any Hasher { typedHasher }
    
    @inlinable
    public var eventsStorageKey: any StorageKey<RC.TBlockEvents> {
        get throws { try config.eventsStorageKey(runtime: self) }
    }
    
    public let typedHasher: ST<RC>.Hasher
    
    public let addressFormat: SS58.AddressFormat
    
    @inlinable
    public func encoder() -> ScaleCodec.Encoder { config.encoder() }
    
    @inlinable
    public func encoder(reservedCapacity count: Int) -> ScaleCodec.Encoder {
        config.encoder(reservedCapacity: count)
    }
    
    @inlinable
    public func decoder(with data: Data) -> ScaleCodec.Decoder { config.decoder(data: data) }
    
    @inlinable
    public func custom(coder type: RuntimeType.Id) -> RuntimeCustomDynamicCoder? {
        try? customCoders.first { try $0.checkType(id: type, runtime: self) }
    }
    
    @inlinable
    public func queryInfoCall<C: Call>(
        extrinsic: Extrinsic<C, ST<RC>.ExtrinsicSignedExtra>
    ) throws -> any RuntimeCall<ST<RC>.DispatchInfo> {
        var encoder = self.encoder()
        try extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: self)
        return try config.queryInfoCall(extrinsic: encoder.output, runtime: self)
    }
    
    @inlinable
    public func queryFeeDetailsCall<C: Call>(
        extrinsic: Extrinsic<C, ST<RC>.ExtrinsicSignedExtra>
    ) throws -> any RuntimeCall<ST<RC>.FeeDetails> {
        var encoder = self.encoder()
        try extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: self)
        return try config.queryFeeDetailsCall(extrinsic: encoder.output, runtime: self)
    }
    
    public init(config: RC, metadata: any Metadata,
                metadataHash: ST<RC>.Hash?,
                genesisHash: ST<RC>.Hash,
                version: ST<RC>.RuntimeVersion,
                properties: ST<RC>.SystemProperties) throws
    {
        self.config = config
        self.metadata = metadata
        self.metadataHash = metadataHash
        self.genesisHash = genesisHash
        self.version = version
        self.properties = properties
        self.addressFormat = properties.ss58Format ?? .default
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
    
    open func validate() throws {
        try extrinsicManager.validate(runtime: self)
    }
}

public extension ExtendedRuntime {
    @inlinable
    func account(ss58: String) throws -> ST<RC>.AccountId {
        try create(account: ST<RC>.AccountId.self, from: ss58)
    }
    
    @inlinable
    func account(pub: any PublicKey) throws -> ST<RC>.AccountId {
        try pub.account(runtime: self)
    }
    
    @inlinable
    func account(raw: Data) throws -> ST<RC>.AccountId {
        try create(account: ST<RC>.AccountId.self, raw: raw)
    }
    
    @inlinable
    func address(account: ST<RC>.AccountId) throws -> ST<RC>.Address {
        try account.address()
    }
    
    @inlinable
    func address(ss58: String) throws -> ST<RC>.Address {
        try account(ss58: ss58).address()
    }
    
    @inlinable
    func address(pub: any PublicKey) throws -> ST<RC>.Address {
        try pub.address(runtime: self)
    }
    
    @inlinable
    func hash(data: Data) throws -> ST<RC>.Hash {
        try typedHasher.hash(data: data, runtime: self)
    }
}

public struct LazyRuntimeTypes<RC: Config>: RuntimeTypes {
    private struct State {
        var block: Result<RuntimeType.Info, Error>?
        var account: Result<RuntimeType.Info, Error>?
        var extrinsic: Result<(call: RuntimeType.Info, addr: RuntimeType.Info,
                               signature: RuntimeType.Info, extra: RuntimeType.Info), Error>?
        var hash: Result<RuntimeType.Info, Error>?
        var dispatchError: Result<RuntimeType.Info, Error>?
        var event: Result<RuntimeType.Info, Error>?
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
    
    public var event: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.event { return try res.get() }
            if let event = self._metadata.outerEnums?.eventType {
                state.event = .success(event)
            } else {
                state.event = Result { try self._config.eventType(metadata: self._metadata) }
            }
            return try state.event!.get()
        }
    }}
    
    public var dispatchError: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.dispatchError { return try res.get() }
            state.dispatchError = Result { try self._config.dispatchErrorType(metadata: self._metadata) }
            return try state.dispatchError!.get()
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
