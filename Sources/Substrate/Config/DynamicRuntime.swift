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
    public typealias TExtrinsicFailureEvent = System.Events.ExtrinsicFailure<TDispatchError>
    public typealias TBlockEvents = BlockEvents<EventRecord<THasher.THash>>
    public typealias TRuntimeVersion = AnyRuntimeVersion
    public typealias TTransactionValidityError = SerializableValue
    public typealias TStorageChangeSet = StorageChangeSet<THasher.THash>
    
    public typealias TMetadataAtVersionRuntimeCall = Api.Metadata.MetadataAtVersion
    public typealias TMetadataVersionsRuntimeCall = Api.Metadata.MetadataVersions
    
    public enum Error: Swift.Error {
        case headerTypeNotFound(String)
        case hashTypeNotFound(header: RuntimeTypeInfo)
        case extrinsicInfoNotFound
        case unknownHashName(String)
    }
    
    public let extrinsicExtensions: [DynamicExtrinsicExtension]
    public let headerTypeName: String
    
    public init(extrinsicExtensions: [DynamicExtrinsicExtension] = Self.allExtensions,
                headerTypeName: String = "sp_runtime.generic.header.Header") {
        self.extrinsicExtensions = extrinsicExtensions
        self.headerTypeName = headerTypeName
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
        let path = headerTypeName.split(separator: ".").map { String($0) }
        guard let type = metadata.resolve(type: path) else {
            throw Error.headerTypeNotFound(headerTypeName)
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


// Helper structs
public extension DynamicRuntime {
    struct Api {
        public struct Metadata {
            public struct Metadata: StaticCodableRuntimeCall {
                public typealias TReturn = VersionedMetadata
                static public let method = "metadata"
                static public var api: String { Api.Metadata.name }
                
                public init(_ params: Void) throws {}
                
                public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {}
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
    }
    
    struct System {
        public struct Events {
            public struct ExtrinsicFailure<Err: SomeDispatchError>: SomeExtrinsicFailureEvent {
                public typealias Err = Err
                public static var pallet: String { System.name }
                public static var name: String { "ExtrinsicFailure" }
                
                public let error: Value<RuntimeTypeId>
                
                public init(params: [Value<RuntimeTypeId>]) throws {
                    guard params.count == 1, let err = params.first else {
                        throw ValueInitializableError<RuntimeTypeId>.wrongValuesCount(in: .sequence(params),
                                                                                      expected: 1,
                                                                                      for: Self.name)
                    }
                    self.error = err
                }
                
                public func asError() throws -> Err {
                    try Err(value: error)
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
