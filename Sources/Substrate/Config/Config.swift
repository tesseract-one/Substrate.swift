//
//  RuntimeConfig.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public typealias ConfigUnsignedInteger = UnsignedInteger & ValueRepresentable & DataConvertible
    & CompactCodable & Swift.Codable & RuntimeCodable & RuntimeDynamicValidatable

// Config split to avoid recursive types
public protocol BasicConfig {
    associatedtype THasher: FixedHasher
    associatedtype TIndex: ConfigUnsignedInteger
    associatedtype TAccountId: AccountId
    associatedtype TAddress: Address<TAccountId>
    associatedtype TSignature: Signature
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & RuntimeDynamicValidatable
    associatedtype TSystemProperties: SystemProperties
    associatedtype TRuntimeVersion: RuntimeVersion
    associatedtype TRuntimeDispatchInfo: RuntimeDynamicDecodable & RuntimeDynamicValidatable
    associatedtype TFeeDetails: RuntimeDynamicDecodable & RuntimeDynamicValidatable
}

public protocol Config {
    associatedtype BC: BasicConfig
    
    associatedtype TBlock: SomeBlock where TBlock.THeader.THasher == SBT<BC>.Hasher
    associatedtype TChainBlock: SomeChainBlock<TBlock>
    associatedtype TBlockEvents: SomeBlockEvents
    associatedtype TExtrinsicFailureEvent: SomeExtrinsicFailureEvent
    associatedtype TDispatchError: SomeDispatchError
    associatedtype TTransactionValidityError: CallError
    associatedtype TTransactionStatus: SomeTransactionStatus<TBlock.THeader.THasher.THash>
    associatedtype TStorageChangeSet: SomeStorageChangeSet<TBlock.THeader.THasher.THash>
    associatedtype TExtrinsicManager: ExtrinsicManager<BC>
    
    // Metadata Info Providers
    func blockType(metadata: any Metadata) throws -> NetworkType.Info
    func hashType(metadata: any Metadata) throws -> NetworkType.Info
    func dispatchErrorType(metadata: any Metadata) throws -> NetworkType.Info
    func transactionValidityErrorType(metadata: any Metadata) throws -> NetworkType.Info
    func accountType(metadata: any Metadata, address: NetworkType.Info) throws -> NetworkType.Info
    // Сan be safely removed after removing metadata v14 (v15 has them)
    func eventType(metadata: any Metadata) throws -> NetworkType.Info
    func extrinsicTypes(metadata: any Metadata) throws -> (call: NetworkType.Info, addr: NetworkType.Info,
                                                           signature: NetworkType.Info, extra: NetworkType.Info)
    // Object Builders
    func hasher(metadata: any Metadata) throws -> ST<Self>.Hasher
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents>
    func queryInfoCall(extrinsic: Data,
                       runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.RuntimeDispatchInfo>
    func queryFeeDetailsCall(extrinsic: Data,
                             runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.FeeDetails>
    func metadataVersionsCall() throws -> any StaticCodableRuntimeCall<[UInt32]>
    func metadataAtVersionCall(version: UInt32) throws -> any StaticCodableRuntimeCall<Optional<OpaqueMetadata>>
    func extrinsicManager() throws -> TExtrinsicManager
    func customCoders() throws -> [RuntimeCustomDynamicCoder]
    // Return Config pallets list for validation
    func pallets(runtime: any Runtime) throws -> [Pallet]
    func runtimeCalls(runtime: any Runtime) throws -> [any (StaticRuntimeCall & RuntimeValidatable).Type]
    // If you want your own Scale Codec coders
    func encoder() -> ScaleCodec.Encoder
    func encoder(reservedCapacity count: Int) -> ScaleCodec.Encoder
    func decoder(data: Data) -> ScaleCodec.Decoder
}

// Config that supports batches
public protocol BatchSupportedConfig: Config {
    associatedtype TBatchCall: SomeBatchCall
    associatedtype TBatchAllCall: SomeBatchCall
    
    func isBatchSupported(metadata: any Metadata) -> Bool
    func batchCalls(runtime: any Runtime) throws -> [SomeBatchCall.Type]
}

@frozen public struct SBT<C: BasicConfig> {
    public typealias Hasher = C.THasher
    public typealias Hash = C.THasher.THash
    public typealias Index = C.TIndex
    public typealias AccountId = C.TAccountId
    public typealias Address = C.TAddress
    public typealias Signature = C.TSignature
    public typealias ExtrinsicEra = C.TExtrinsicEra
    public typealias ExtrinsicPayment = C.TExtrinsicPayment
    public typealias SystemProperties = C.TSystemProperties
    public typealias RuntimeVersion = C.TRuntimeVersion
    public typealias RuntimeDispatchInfo = C.TRuntimeDispatchInfo
    public typealias FeeDetails = C.TFeeDetails
    
    public typealias Version = C.TRuntimeVersion.TVersion
}

public typealias SBC<C: Config> = C.BC

@frozen public struct ST<C: Config> {
    public typealias Hasher = SBT<SBC<C>>.Hasher
    public typealias Hash = SBT<SBC<C>>.Hash
    public typealias Index = SBT<SBC<C>>.Index
    public typealias AccountId = SBT<SBC<C>>.AccountId
    public typealias Address = SBT<SBC<C>>.Address
    public typealias Signature = SBT<SBC<C>>.Signature
    public typealias ExtrinsicEra = SBT<SBC<C>>.ExtrinsicEra
    public typealias ExtrinsicPayment = SBT<SBC<C>>.ExtrinsicPayment
    public typealias SystemProperties = SBT<SBC<C>>.SystemProperties
    public typealias RuntimeVersion = SBT<SBC<C>>.RuntimeVersion
    public typealias RuntimeDispatchInfo = SBT<SBC<C>>.RuntimeDispatchInfo
    public typealias FeeDetails = SBT<SBC<C>>.FeeDetails
    public typealias Version = SBT<SBC<C>>.Version
    
    public typealias Block = C.TBlock
    public typealias BlockHeader = C.TBlock.THeader
    public typealias BlockNumber = C.TBlock.THeader.TNumber
    public typealias ChainBlock = C.TChainBlock
    public typealias BlockEvents = C.TBlockEvents
    public typealias ExtrinsicFailureEvent = C.TExtrinsicFailureEvent
    public typealias DispatchError = C.TDispatchError
    public typealias TransactionValidityError = C.TTransactionValidityError
    public typealias TransactionStatus = C.TTransactionStatus
    public typealias StorageChangeSet = C.TStorageChangeSet
    public typealias ExtrinsicManager = C.TExtrinsicManager
    
    public typealias SigningParams = ExtrinsicManager.TSigningParams
    public typealias SigningParamsPartial = SigningParams.TPartial
    
    public typealias ExtrinsicSignedExtra = ExtrinsicManager.TSignedExtra
    public typealias ExtrinsicUnsignedParams = ExtrinsicManager.TUnsignedParams
    public typealias ExtrinsicUnsignedExtra = ExtrinsicManager.TUnsignedExtra
    
    public typealias AnyExtrinsic<C: Call> =
        Extrinsic<C, Either<ExtrinsicUnsignedExtra, ExtrinsicSignedExtra>>
    public typealias SignedExtrinsic<C: Call> = Extrinsic<C, ExtrinsicSignedExtra>
    public typealias UnsignedExtrinsic<C: Call> = Extrinsic<C, ExtrinsicUnsignedExtra>
    public typealias SigningPayload<C: Call> =
        ExtrinsicSignPayload<C, ExtrinsicManager.TSigningExtra>
}

public extension ST where C: BatchSupportedConfig {
    typealias BatchCall = C.TBatchCall
    typealias BatchAllCall = C.TBatchAllCall
}

// Default isBatchSupported implementation
public extension BatchSupportedConfig {
    func isBatchSupported(metadata: Metadata) -> Bool {
        metadata.resolve(pallet: TBatchCall.pallet)?.callIndex(name: TBatchCall.name) != nil &&
        metadata.resolve(pallet: TBatchAllCall.pallet)?.callIndex(name: TBatchAllCall.name) != nil
    }
    
    func batchCalls(runtime: any Runtime) throws -> [SomeBatchCall.Type] {
        [TBatchCall.self, TBatchAllCall.self]
    }
}

// namespace for Configs declaration
@frozen public struct Configs {
    // Type for Config registrations. Provides better constructors for Api
    @frozen public struct Registry<C: Config, Ext> {
        public let config: C
        @inlinable public init(config: C) { self.config = config }
    }
    
    @inlinable
    static func defaultPallets<C: Config>(runtime: any Runtime, config: C) throws -> [Pallet] {
        try [BaseSystemPallet<C>(runtime: runtime, config: config)]
    }
    
    @inlinable
    static func defaultRuntimeCalls<C: Config>(
        runtime: any Runtime, config: C
    ) -> [any (StaticRuntimeCall & RuntimeValidatable).Type] {
        [TransactionQueryInfoRuntimeCall<ST<C>.RuntimeDispatchInfo>.self,
         TransactionQueryFeeDetailsRuntimeCall<ST<C>.FeeDetails>.self]
    }
}

// Default constructors
public extension Config {
    @inlinable
    func encoder() -> ScaleCodec.Encoder { ScaleCodec.encoder() }
    
    @inlinable
    func encoder(reservedCapacity count: Int) -> ScaleCodec.Encoder {
        ScaleCodec.encoder(reservedCapacity: count)
    }
    
    @inlinable
    func decoder(data: Data) -> ScaleCodec.Decoder { ScaleCodec.decoder(from: data) }
    
    @inlinable
    func metadataVersionsCall() throws -> any StaticCodableRuntimeCall<[UInt32]> {
        MetadataVersionsRuntimeCall()
    }
    
    @inlinable
    func metadataAtVersionCall(version: UInt32) throws -> any StaticCodableRuntimeCall<Optional<OpaqueMetadata>> {
        MetadataAtVersionRuntimeCall(version: version)
    }
    
    @inlinable
    func customCoders() throws -> [RuntimeCustomDynamicCoder] {
        Configs.customCoders
    }
    
    @inlinable
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<ST<Self>.BlockEvents> {
        EventsStorageKey<ST<Self>.BlockEvents>()
    }
    
    @inlinable
    func queryInfoCall(extrinsic: Data,
                       runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.RuntimeDispatchInfo> {
        TransactionQueryInfoRuntimeCall(extrinsic: extrinsic)
    }
    
    @inlinable
    func queryFeeDetailsCall(extrinsic: Data,
                             runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.FeeDetails> {
        TransactionQueryFeeDetailsRuntimeCall(extrinsic: extrinsic)
    }
    
    @inlinable
    func pallets(runtime: any Runtime) throws -> [Pallet] {
        try Configs.defaultPallets(runtime: runtime, config: self)
    }
    
    @inlinable
    func runtimeCalls(runtime: any Runtime) throws -> [any (StaticRuntimeCall & RuntimeValidatable).Type] {
        Configs.defaultRuntimeCalls(runtime: runtime, config: self)
    }
}

// Сan be safely removed after removing metadata v14 (v15 has types inside)
public extension Config {
    func extrinsicTypes(metadata: any Metadata) throws -> (call: NetworkType.Info, addr: NetworkType.Info,
                                                           signature: NetworkType.Info, extra: NetworkType.Info)
    {
        var addressTypeId: NetworkType.Id? = nil
        var sigTypeId: NetworkType.Id? = nil
        var extraTypeId: NetworkType.Id? = nil
        var callTypeId: NetworkType.Id? = nil
        for param in metadata.extrinsic.type.type.parameters {
            switch param.name.lowercased() {
            case "address": addressTypeId = param.type
            case "signature": sigTypeId = param.type
            case "extra": extraTypeId = param.type
            case "call": callTypeId = param.type
            default: continue
            }
        }
        guard let addressTypeId = addressTypeId,
              let sigTypeId = sigTypeId,
              let extraTypeId = extraTypeId,
              let callTypeId = callTypeId,
              let addressType = metadata.resolve(type: addressTypeId),
              let sigType = metadata.resolve(type: sigTypeId),
              let extraType = metadata.resolve(type: extraTypeId),
              let callType = metadata.resolve(type: callTypeId) else
        {
            throw ConfigTypeLookupError.extrinsicTypesNotFound
        }
        return (call: NetworkType.Info(id: callTypeId, type: callType),
                addr: NetworkType.Info(id: addressTypeId, type: addressType),
                signature: NetworkType.Info(id: sigTypeId, type: sigType),
                extra: NetworkType.Info(id: extraTypeId, type: extraType))
    }
    
    func eventType(metadata: any Metadata) throws -> NetworkType.Info {
        let eventsName = EventsStorageKey<ST<Self>.BlockEvents>.name
        let eventsPallet = EventsStorageKey<ST<Self>.BlockEvents>.pallet
        guard let beStorage = metadata.resolve(pallet: eventsPallet)?.storage(name: eventsName) else {
            throw ConfigTypeLookupError.typeNotFound(name: eventsName,
                                                     selector: "\(eventsPallet).Storage")
        }
        guard let id = ST<Self>.BlockEvents.eventTypeId(metadata: metadata,
                                                        events: beStorage.types.value.id) else {
            throw ConfigTypeLookupError.typeNotFound(name: "Event",
                                                     selector: "EventRecord.event")
        }
        guard let info = metadata.resolve(type: id) else {
            throw ConfigTypeLookupError.typeNotFound(id: id)
        }
        return NetworkType.Info(id: id, type: info)
    }
}

public extension Config where ST<Self>.Hasher: StaticHasher {
    // Static hasher creates Hash without type lookup
    func hashType(metadata: any Metadata) throws -> NetworkType.Info {
        throw NetworkType.IdNeverCalledError()
    }
    // Static Hasher can be returned by singleton instance
    func hasher(metadata: Metadata) throws -> ST<Self>.Hasher { ST<Self>.Hasher.instance }
}

// Static Block doesn't need runtime type
public extension Config where TBlock: StaticBlock {
    func blockType(metadata: Metadata) throws -> NetworkType.Info {
        throw NetworkType.IdNeverCalledError()
    }
}

// Static Transaction Validity Error doesn't need runtime type
public extension Config where TTransactionValidityError: StaticCallError {
    func transactionValidityErrorType(metadata: any Metadata) throws -> NetworkType.Info {
        throw NetworkType.IdNeverCalledError()
    }
}

// Static Dispatch Error doesn't need runtime type
public extension Config where TDispatchError: StaticCallError {
    func dispatchErrorType(metadata: any Metadata) throws -> NetworkType.Info {
        throw NetworkType.IdNeverCalledError()
    }
}

// Static Account doesn't need runtime type
public extension Config where ST<Self>.AccountId: StaticAccountId {
    func accountType(metadata: any Metadata, address: NetworkType.Info) throws -> NetworkType.Info {
        throw NetworkType.IdNeverCalledError()
    }
}

public extension Config where ST<Self>.ExtrinsicPayment: Default {
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment {
        .default
    }
}

public enum ConfigTypeLookupError: Error {
    case paymentTypeNotFound
    case extrinsicTypesNotFound
    case hashTypeNotFound
    case badHeaderType(header: NetworkType.Info)
    case typeNotFound(id: NetworkType.Id)
    case typeNotFound(name: String, selector: String)
    case cantProvideDefaultPayment(forType: NetworkType.Info)
    case unknownHashName(String)
}
