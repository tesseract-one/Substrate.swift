//
//  RuntimeConfig.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public protocol Config {
    associatedtype THasher: FixedHasher
    associatedtype TIndex: UnsignedInteger & DataConvertible & CompactCodable & Swift.Codable & RuntimeCodable
    associatedtype TAccountId: AccountId
    associatedtype TAddress: Address where TAddress.TAccountId == TAccountId
    associatedtype TSignature: Signature
    associatedtype TBlock: SomeBlock where TBlock.THeader.THasher == THasher
    associatedtype TChainBlock: SomeChainBlock<TBlock>
    
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & Default
    associatedtype TBlockEvents: SomeBlockEvents
    associatedtype TExtrinsicFailureEvent: SomeExtrinsicFailureEvent
    associatedtype TDispatchError: ApiError
    associatedtype TTransactionValidityError: ApiError
    associatedtype TDispatchInfo: RuntimeDynamicDecodable
    associatedtype TFeeDetails: RuntimeDynamicDecodable
    associatedtype TTransactionStatus: SomeTransactionStatus<TBlock.THeader.THasher.THash>
    associatedtype TSystemProperties: SystemProperties
    associatedtype TRuntimeVersion: RuntimeVersion
    associatedtype TStorageChangeSet: SomeStorageChangeSet
    associatedtype TExtrinsicManager: ExtrinsicManager<Self>
    
    // Metadata Info Providers
    func blockType(metadata: any Metadata) throws -> RuntimeType.Info
    func dispatchInfoType(metadata: any Metadata) throws -> RuntimeType.Info
    func feeDetailsType(metadata: any Metadata) throws -> RuntimeType.Info
    func dispatchErrorType(metadata: any Metadata) throws -> RuntimeType.Info
    func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeType.Info
    func accountType(metadata: any Metadata, address: RuntimeType.Info) throws -> RuntimeType.Info
    // Both can be safely removed after removing metadata v14 (v15 has them)
    func eventType(metadata: any Metadata) throws -> RuntimeType.Info
    func extrinsicTypes(metadata: any Metadata) throws -> (call: RuntimeType.Info, addr: RuntimeType.Info,
                                                           signature: RuntimeType.Info, extra: RuntimeType.Info)
    // Object Builders
    func hasher(metadata: any Metadata) throws -> THasher
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents>
    func queryInfoCall(extrinsic: Data, runtime: any Runtime) throws -> any RuntimeCall<TDispatchInfo>
    func queryFeeDetailsCall(extrinsic: Data, runtime: any Runtime) throws -> any RuntimeCall<TFeeDetails>
    func metadataVersionsCall() throws -> any StaticCodableRuntimeCall<[UInt32]>
    func metadataAtVersionCall(version: UInt32) throws -> any StaticCodableRuntimeCall<Optional<OpaqueMetadata>>
    func extrinsicManager() throws -> TExtrinsicManager
    // If you want your own Scale Codec coders
    func encoder() -> ScaleCodec.Encoder
    func decoder(data: Data) -> ScaleCodec.Decoder
}

// Default Encoder and Decoder
public extension Config {
    @inlinable
    func encoder() -> ScaleCodec.Encoder { ScaleCodec.encoder() }
    @inlinable
    func decoder(data: Data) -> ScaleCodec.Decoder { ScaleCodec.decoder(from: data) }
}

// Static Hasher can be returned by instance
public extension Config where THasher: StaticHasher {
    func hasher(metadata: Metadata) throws -> THasher { THasher.instance }
}

// Static Block doesn't need runtime type
public extension Config where TBlock: StaticBlock {
    func blockType(metadata: Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

public protocol BatchSupportedConfig: Config {
    associatedtype TBatchCall: SomeBatchCall
    associatedtype TBatchAllCall: SomeBatchCall
    
    func isBatchSupported(metadata: any Metadata) -> Bool
}

public extension BatchSupportedConfig {
    func isBatchSupported(metadata: Metadata) -> Bool {
        metadata.resolve(pallet: TBatchCall.pallet)?.callIndex(name: TBatchCall.name) != nil &&
        metadata.resolve(pallet: TBatchAllCall.pallet)?.callIndex(name: TBatchAllCall.name) != nil
    }
}

// Type for Config registrations. Provides better constructors for RootApi
public struct ConfigRegistry<C: Config> {
    public let config: C
    @inlinable public init(config: C) { self.config = config }
}
