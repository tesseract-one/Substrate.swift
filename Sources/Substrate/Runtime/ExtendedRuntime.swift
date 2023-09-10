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
    public let types: DynamicTypes
    public let isBatchSupported: Bool
    public let staticTypes: Synced<TypeRegistry<TypeDefinition.TypeId>>
    public private(set) var customCoders: [ObjectIdentifier: RuntimeCustomDynamicCoder]!
    
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
    
    public func custom(coder type: TypeDefinition) -> RuntimeCustomDynamicCoder? {
        customCoders[type.objectId]
    }
    
    @inlinable
    public func queryInfoCall<C: Call>(
        extrinsic: Extrinsic<C, ST<RC>.ExtrinsicSignedExtra>
    ) throws -> any RuntimeCall<ST<RC>.RuntimeDispatchInfo> {
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
                types: DynamicTypes,
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
        self.types = types
        self.staticTypes = Synced(value: TypeRegistry())
        self.extrinsicManager = try config.extrinsicManager(types: types, metadata: metadata)
        guard let hasher = ST<RC>.Hasher(type: types.hasher.value) else {
            let hasher = try types.hasher.get()
            throw DynamicTypes.LookupError.unknownHasherType(type: hasher.hasher.type.name)
        }
        self.typedHasher = hasher
        if let bc = config as? any BatchSupportedConfig {
            self.isBatchSupported = bc.isBatchSupported(types: types, metadata: metadata)
        } else {
            self.isBatchSupported = false
        }
        self.customCoders = nil
        let customCoders = try config.customCoders(types: types, metadata: metadata)
        let codersMap = try metadata.reduce(
            types: Dictionary<ObjectIdentifier, RuntimeCustomDynamicCoder>()
        ) { out, tdef in
            for coder in customCoders where try coder.checkType(type: tdef, runtime: self) {
                out[tdef.objectId] = coder
            }
        }
        self.customCoders = codersMap
    }
    
    open func validate() throws {
        // Basic types
        try validate(type: ST<RC>.AccountId.self, info: types.account,
                     isStatic: ST<RC>.AccountId.self is any StaticAccountId.Type)
        try validate(type: ST<RC>.Block.self, info: types.block,
                     isStatic: ST<RC>.Block.self is any StaticBlock.Type)
        try validate(type: ST<RC>.Hash.self, info: types.hash,
                     isStatic: ST<RC>.Hash.self is any StaticHash.Type)
        try validate(type: ST<RC>.DispatchError.self, info: types.dispatchError,
                     isStatic: ST<RC>.DispatchError.self is any StaticCallError.Type)
        try validate(type: ST<RC>.TransactionValidityError.self,
                     info: types.transactionValidityError,
                     isStatic: ST<RC>.TransactionValidityError.self is any StaticCallError.Type)
        // Extrinsic and Extenstions
        try extrinsicManager.validate(runtime: self)
        // Static types provided by Config
        try config.frames(runtime: self).voidErrorMap { $0.validate(runtime: self) }.get()
        try config.runtimeCalls(runtime: self).voidErrorMap { $0.validate(runtime: self) }.get()
    }
    
    public func validate<T: ValidatableTypeStatic>(type: T.Type, info: DynamicTypes.Maybe<TypeDefinition>,
                                                   isStatic: Bool) throws
    {
        switch info {
        case .success(let info): try type.validate(as: info, in: self).get()
        case .failure(let err): guard isStatic else { throw err }
        }
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
