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
    associatedtype TIndex: UnsignedInteger & DataConvertible & CompactCodable & Codable & ScaleRuntimeCodable
    associatedtype TAccountId: AccountId
    associatedtype TAddress: Address where TAddress.TAccountId == TAccountId
    associatedtype TSignature: Signature
    associatedtype TBlock: SomeBlock where TBlock.THeader.THasher == THasher
    associatedtype TSignedBlock: SomeChainBlock<TBlock>
    
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & Default
    associatedtype TBlockEvents: SomeBlockEvents
    associatedtype TExtrinsicFailureEvent: SomeExtrinsicFailureEvent<TDispatchError>
    associatedtype TDispatchError: SomeDispatchError
    associatedtype TDispatchInfo: ScaleRuntimeDynamicDecodable
    associatedtype TFeeDetails: ScaleRuntimeDynamicDecodable
    associatedtype TTransactionStatus: SomeTransactionStatus<TBlock.THeader.THasher.THash>
    associatedtype TSystemProperties: SystemProperties
    associatedtype TRuntimeVersion: RuntimeVersion
    associatedtype TTransactionValidityError: Decodable
   
    associatedtype TExtrinsicManager: ExtrinsicManager<Self>
    
    func eventsStorageKey(metadata: Metadata) throws -> any StorageKey<TBlockEvents>
    func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo
    func extrinsicTypes(
        metadata: Metadata
    ) throws -> (addr: RuntimeTypeInfo, signature: RuntimeTypeInfo, extra: RuntimeTypeInfo)
    func hasher(metadata: Metadata) throws -> THasher
    func extrinsicManager() throws -> TExtrinsicManager
}

public extension Config where THasher: StaticHasher {
    func hasher(metadata: Metadata) throws -> THasher { THasher.instance }
}

public extension Config where TBlock.THeader: StaticBlockHeader {
    func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo {
        fatalError("Should not be called for StaticBlockHeader!")
    }
}
