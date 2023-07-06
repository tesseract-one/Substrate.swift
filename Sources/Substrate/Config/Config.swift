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
    associatedtype TSignedBlock: SomeChainBlock<TBlock>
    
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & Default
    associatedtype TBlockEvents: SomeBlockEvents
    associatedtype TExtrinsicFailureEvent: SomeExtrinsicFailureEvent<TDispatchError>
    associatedtype TDispatchError: ApiError
    associatedtype TTransactionValidityError: ApiError
    associatedtype TDispatchInfo: RuntimeDynamicDecodable
    associatedtype TFeeDetails: RuntimeDynamicDecodable
    associatedtype TTransactionStatus: SomeTransactionStatus<TBlock.THeader.THasher.THash>
    associatedtype TSystemProperties: SystemProperties
    associatedtype TRuntimeVersion: RuntimeVersion
   
    associatedtype TStorageChangeSet: SomeStorageChangeSet
   
    associatedtype TTransactionPaymentQueryInfoRuntimeCall: SomeTransactionPaymentQueryInfoRuntimeCall<TDispatchInfo>
    associatedtype TTransactionPaymentFeeDetailsRuntimeCall: SomeTransactionPaymentFeeDetailsRuntimeCall<TFeeDetails>
    associatedtype TMetadataAtVersionRuntimeCall: SomeMetadataAtVersionRuntimeCall
    associatedtype TMetadataVersionsRuntimeCall: SomeMetadataVersionsRuntimeCall
    
    associatedtype TExtrinsicManager: ExtrinsicManager<Self>
    
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents>
    func hasher(metadata: any Metadata) throws -> THasher
    func extrinsicManager() throws -> TExtrinsicManager
    func encoder() -> ScaleCodec.Encoder
    func decoder(data: Data) -> ScaleCodec.Decoder
    
    func blockHeaderType(metadata: any Metadata) throws -> RuntimeTypeInfo
    func dispatchInfoType(metadata: any Metadata) throws -> RuntimeTypeInfo
    func feeDetailsType(metadata: any Metadata) throws -> RuntimeTypeInfo
    func dispatchErrorType(metadata: any Metadata) throws -> RuntimeTypeInfo
    func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeTypeInfo
    
    // Can be safely removed after removing metadata v14 (v15 has them)
    func extrinsicTypes(metadata: any Metadata) throws -> (call: RuntimeTypeInfo, addr: RuntimeTypeInfo,
                                                           signature: RuntimeTypeInfo, extra: RuntimeTypeInfo)
    func eventType(metadata: any Metadata) throws -> RuntimeTypeInfo
}

public extension Config {
    @inlinable
    func encoder() -> ScaleCodec.Encoder { ScaleCodec.encoder() }
    @inlinable
    func decoder(data: Data) -> ScaleCodec.Decoder { ScaleCodec.decoder(from: data) }
}

public extension Config where THasher: StaticHasher {
    func hasher(metadata: Metadata) throws -> THasher { THasher.instance }
}

public extension Config where TBlock.THeader: StaticBlockHeader {
    func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo {
        fatalError("Should not be called for StaticBlockHeader!")
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

public struct ConfigRegistry<C: Config> {
    public let config: C
    @inlinable public init(config: C) { self.config = config }
}
