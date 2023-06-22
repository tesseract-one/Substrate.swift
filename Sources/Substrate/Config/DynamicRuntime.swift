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
    public typealias TTransactionValidityError = AnyTransactionValidityError
    public typealias TExtrinsicFailureEvent = System.Events.ExtrinsicFailure<TDispatchError>
    public typealias TBlockEvents = BlockEvents<EventRecord<THasher.THash>>
    public typealias TRuntimeVersion = AnyRuntimeVersion
    public typealias TStorageChangeSet = StorageChangeSet<THasher.THash>
    
    public typealias TMetadataAtVersionRuntimeCall = Api.Metadata.MetadataAtVersion
    public typealias TMetadataVersionsRuntimeCall = Api.Metadata.MetadataVersions
    public typealias TTransactionPaymentQueryInfoRuntimeCall = Api.TransactionPayment.QueryInfo<TDispatchInfo>
    public typealias TTransactionPaymentFeeDetailsRuntimeCall = Api.TransactionPayment.QueryFeeDetails<TFeeDetails>
    
    public enum Error: Swift.Error {
        case typeNotFound(name: String, selector: Set<String>)
        case hashTypeNotFound(header: RuntimeTypeInfo)
        case extrinsicInfoNotFound
        case unknownHashName(String)
    }
    
    public let extrinsicExtensions: [DynamicExtrinsicExtension]
    public let headerSelector: Set<String>
    public let dispatchInfoSelector: Set<String>
    public let dispatchErrorSelector: Set<String>
    public let transactionValidityErrorSelector: Set<String>
    public let feeDetailsSelector: Set<String>
    
    public init(extrinsicExtensions: [DynamicExtrinsicExtension] = Self.allExtensions,
                headerSelector: [String] = ["Header"],
                dispatchInfoSelector: [String] = ["DispatchInfo"],
                dispatchErrorSelector: [String] = ["DispatchError"],
                transactionValidityErrorSelector: [String] = ["TransactionValidityError"],
                feeDetailsSelector: [String] = ["FeeDetails"])
    {
        self.extrinsicExtensions = extrinsicExtensions
        self.headerSelector = Set(headerSelector)
        self.dispatchInfoSelector = Set(dispatchInfoSelector)
        self.dispatchErrorSelector = Set(dispatchErrorSelector)
        self.transactionValidityErrorSelector = Set(transactionValidityErrorSelector)
        self.feeDetailsSelector = Set(feeDetailsSelector)
    }
    
    public func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents> {
        try System.Storage.Events<TBlockEvents>((), runtime: runtime)
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
        guard let type = metadata.search(type: {headerSelector.isSubset(of: $0)}) else {
            throw Error.typeNotFound(name: "header", selector: headerSelector)
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
    
    public func dispatchInfoType(metadata: any Metadata) throws -> RuntimeTypeInfo {
        guard let type = metadata.search(type: {dispatchInfoSelector.isSubset(of: $0)}) else {
            throw Error.typeNotFound(name: "dispatchInfo", selector: dispatchInfoSelector)
        }
        return type
    }
    
    public func dispatchErrorType(metadata: any Metadata) throws -> RuntimeTypeInfo {
        guard let type = metadata.search(type: {dispatchErrorSelector.isSubset(of: $0)}) else {
            throw Error.typeNotFound(name: "dispatchError", selector: dispatchErrorSelector)
        }
        return type
    }
    
    public func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeTypeInfo {
        guard let type = metadata.search(type: {transactionValidityErrorSelector.isSubset(of: $0)}) else {
            throw Error.typeNotFound(name: "transactionValidityError", selector: transactionValidityErrorSelector)
        }
        return type
    }
    
    public func feeDetailsType(metadata: any Metadata) throws -> RuntimeTypeInfo {
        guard let type = metadata.search(type: {feeDetailsSelector.isSubset(of: $0)}) else {
            throw Error.typeNotFound(name: "feeDetails", selector: feeDetailsSelector)
        }
        return type
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


// Helper structs
public extension DynamicRuntime {
    struct Api {
        public struct Metadata {
            public struct Metadata: StaticCodableRuntimeCall {
                public typealias TReturn = VersionedMetadata
                static public let method = "metadata"
                static public var api: String { Api.Metadata.name }
                
                public init(_ params: Void) throws {}
                
                public func encodeParams(in encoder: ScaleEncoder) throws {}
            }
            
            public struct MetadataAtVersion: SomeMetadataAtVersionRuntimeCall {
                public typealias TReturn = Optional<OpaqueMetadata>
                let version: UInt32
                
                public init(version: UInt32) {
                    self.version = version
                }
                
                public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {
                    try encoder.encode(version)
                }
                
                static public let method = "metadata_at_version"
                static public var api: String { Api.Metadata.name }
            }
            
            public struct MetadataVersions: SomeMetadataVersionsRuntimeCall {
                public typealias TReturn = [UInt32]
                static public let method = "metadata_versions"
                static public var api: String { Api.Metadata.name }
                
                public init() {}
                
                public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {}
            }
            
            public static let name = "Metadata"
        }
        
        public struct TransactionPayment {
            public struct QueryInfo<DI: ScaleRuntimeDynamicDecodable>: SomeTransactionPaymentQueryInfoRuntimeCall {
                public typealias TReturn = DI
                
                public let extrinsic: Data
                
                public init(extrinsic: Data) {
                    self.extrinsic = extrinsic
                }
                
                public func encodeParams(in encoder: ScaleEncoder, runtime: Runtime) throws {
                    try encoder.encode(extrinsic).encode(UInt32(extrinsic.count))
                }
                
                public func decode(returnFrom decoder: ScaleCodec.ScaleDecoder, runtime: Runtime) throws -> DI {
                    try TReturn(from: decoder, runtime: runtime) { runtime in
                        try runtime.types.dispatchInfo.id
                    }
                }
                
                public static var method: String { "query_info" }
                public static var api: String { TransactionPayment.name }
            }
            
            public struct QueryFeeDetails<FD: ScaleRuntimeDynamicDecodable>:
                    SomeTransactionPaymentFeeDetailsRuntimeCall
            {
                public typealias TReturn = FD
                
                public let extrinsic: Data
                
                public init(extrinsic: Data) {
                    self.extrinsic = extrinsic
                }
                
                public func encodeParams(in encoder: ScaleEncoder, runtime: Runtime) throws {
                    try encoder.encode(extrinsic).encode(UInt32(extrinsic.count))
                }
                
                public func decode(returnFrom decoder: ScaleCodec.ScaleDecoder, runtime: Runtime) throws -> FD {
                    try TReturn(from: decoder, runtime: runtime) { runtime in
                        try runtime.types.feeDetails.id
                    }
                }
                
                public static var method: String { "query_fee_details" }
                public static var api: String { TransactionPayment.name }
            }
            
            public static let name = "TransactionPaymentApi"
        }
    }
    
    struct System {
        public struct Events {
            public struct ExtrinsicFailure<Err: ApiError>: SomeExtrinsicFailureEvent {
                public typealias Err = Err
                public static var pallet: String { System.name }
                public static var name: String { "ExtrinsicFailure" }
                
                public let error: Err
                
                public init(paramsFrom decoder: ScaleDecoder, runtime: Runtime) throws {
                    self.error = try Err(from: decoder, runtime: runtime)
                }
            }
        }
        public struct Storage {
            public struct Events<BE: SomeBlockEvents>: StaticStorageKey {
                public typealias TParams = Void
                public typealias TValue = BE
                
                public static var name: String { "Events" }
                public static var pallet: String { System.name }
                
                public init(_ params: TParams, runtime: any Runtime) throws {}
                public init(decodingPath decoder: ScaleDecoder, runtime: any Runtime) throws {}
                public var pathHash: Data { Data() }
            }
        }
        public static let name = "System"
    }
}
