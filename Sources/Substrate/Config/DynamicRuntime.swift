//
//  DynamicRuntime.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import Serializable

public struct DynamicRuntime: Config {
    public typealias THasher = AnyFixedHasher
    public typealias TIndex = UInt256
    public typealias TSystemProperties = AnySystemProperties
    public typealias TAccountId = AccountId32
    public typealias TAddress = MultiAddress<TAccountId, TIndex>
    public typealias TSignature = MultiSignature
    public typealias TBlock = Block<AnyBlockHeader<THasher>, BlockExtrinsic<TExtrinsicManager>>
    public typealias TSignedBlock = ChainBlock<TBlock, SerializableValue>
    
    public typealias TExtrinsicManager = ExtrinsicV4Manager<Self, DynamicSignedExtensionsProvider<Self>>
    public typealias TTransactionStatus = TransactionStatus<THasher.THash, THasher.THash>
    
    public typealias TExtrinsicEra = ExtrinsicEra
    public typealias TExtrinsicPayment = UInt256
    public typealias TFeeDetails = Value<RuntimeTypeId>
    public typealias TDispatchInfo = Value<RuntimeTypeId>
    public typealias TDispatchError = AnyDispatchError
    public typealias TExtrinsicFailureEvent = ExtrinsicFailureEvent<TDispatchError>
    public typealias TBlockEvents = BlockEvents<EventRecord<THasher.THash>>
    public typealias TRuntimeVersion = AnyRuntimeVersion
    public typealias TTransactionValidityError = SerializableValue
    
    public enum Error: Swift.Error {
        case headerTypeNotFound(String)
        case hashTypeNotFound(header: RuntimeTypeInfo)
        case extrinsicInfoNotFound
        case unknownHashName(String)
    }
    
    public let extrinsicExtensions: [DynamicExtrinsicExtension]
    public let headerName: String
    
    public init(extrinsicExtensions: [DynamicExtrinsicExtension] = Self.allExtensions,
                headerName: String = "Header") {
        self.extrinsicExtensions = extrinsicExtensions
        self.headerName = headerName
    }
    
    public func eventsStorageKey(metadata: Metadata) throws -> any StorageKey<TBlockEvents> {
        SystemEventsStorageKey<TBlockEvents>()
    }
    
    public func extrinsicManager() throws -> TExtrinsicManager {
        let provider = DynamicSignedExtensionsProvider<Self>(extensions: extrinsicExtensions,
                                                             version: TExtrinsicManager.version)
        return TExtrinsicManager(extensions: provider)
    }
    
    public func hasher(metadata: Metadata) throws -> AnyFixedHasher {
        let header = try blockHeaderType(metadata: metadata)
        let hashType = header.type.parameters.first { $0.name == "Hash" }?.type
        guard let hashType = hashType, let hashName = metadata.resolve(type: hashType)?.path.last else {
            throw Error.hashTypeNotFound(header: header)
        }
        guard let hasher = AnyFixedHasher(name: hashName) else {
            throw Error.unknownHashName(hashName)
        }
        return hasher
    }
    
    public func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo {
        guard let type = metadata.resolve(type: headerName) else {
            throw Error.headerTypeNotFound(headerName)
        }
        return type
    }
    
    public func extrinsicTypes(
        metadata: Metadata
    ) throws -> (addr: RuntimeTypeInfo, signature: RuntimeTypeInfo, extra: RuntimeTypeInfo) {
        var addressTypeId: RuntimeTypeId? = nil
        var sigTypeId: RuntimeTypeId? = nil
        var extraTypeId: RuntimeTypeId? = nil
        for param in metadata.extrinsic.type.type.parameters {
            switch param.name.lowercased() {
            case "address": addressTypeId = param.type
            case "signature": sigTypeId = param.type
            case "extra": extraTypeId = param.type
            default: continue
            }
        }
        guard let addressTypeId = addressTypeId,
              let sigTypeId = sigTypeId,
              let extraTypeId = extraTypeId,
              let addressType = metadata.resolve(type: addressTypeId),
              let sigType = metadata.resolve(type: sigTypeId),
              let extraType = metadata.resolve(type: extraTypeId) else {
            throw Error.extrinsicInfoNotFound
        }
        return (addr: RuntimeTypeInfo(id: addressTypeId, type: addressType),
                signature: RuntimeTypeInfo(id: sigTypeId, type: sigType),
                extra: RuntimeTypeInfo(id: extraTypeId, type: extraType))
    }
    
    public static let allExtensions: [DynamicExtrinsicExtension] = [
        DynamicCheckSpecVersionExtension(),
        DynamicCheckTxVersionExtension(),
        DynamicCheckGenesisExtension(),
        DynamicCheckNonZeroSenderExtension(),
        DynamicCheckNonceExtension(),
        DynamicCheckMortalitySignedExtension(),
        DynamicCheckWeightExtension(),
        DynamicChargeTransactionPaymentExtension(),
        DynamicPrevalidateAttestsExtension()
    ]
}