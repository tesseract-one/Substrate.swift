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

open class ExtendedRuntime<RC: Config>: BasicRuntime<RC> {
    public let genesisHash: ST<RC>.Hash
    public let version: ST<RC>.RuntimeVersion
    public let properties: ST<RC>.SystemProperties
    public let metadataHash: ST<RC>.Hash?
    
    @inlinable
    public var eventsStorageKey: any StorageKey<RC.TBlockEvents> {
        get throws { try config.eventsStorageKey(runtime: self) }
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
        self.metadataHash = metadataHash
        self.genesisHash = genesisHash
        self.version = version
        self.properties = properties
        try super.init(config: config, metadata: metadata, types: types,
                       addressFormat: properties.ss58Format ?? .default)
    }
    
    open override func validate() throws {
        try super.validate()
        // Basic types
        try validate(type: ST<RC>.AccountId.self, info: types.account,
                     isStatic: ST<RC>.AccountId.self is any StaticAccountId.Type)
        try validate(type: ST<RC>.Block.self, info: types.block,
                     isStatic: ST<RC>.Block.self is any StaticBlock.Type)
        try validate(type: ST<RC>.DispatchError.self, info: types.dispatchError,
                     isStatic: ST<RC>.DispatchError.self is any StaticCallError.Type)
        try validate(type: ST<RC>.TransactionValidityError.self,
                     info: types.transactionValidityError,
                     isStatic: ST<RC>.TransactionValidityError.self is any StaticCallError.Type)
        // Static types provided by Config
        try config.frames(runtime: self).voidErrorMap { $0.validate(runtime: self) }.get()
        try config.runtimeApis(runtime: self).voidErrorMap { $0.validate(runtime: self) }.get()
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
