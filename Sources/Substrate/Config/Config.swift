//
//  RuntimeConfig.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public typealias ConfigUnsignedInteger = UnsignedInteger & ValueRepresentable & DataConvertible
    & CompactCodable & Swift.Codable & RuntimeCodable & IdentifiableType

// Config split to avoid recursive types
public protocol BasicConfig {
    associatedtype THasher: FixedHasher
    associatedtype TIndex: ConfigUnsignedInteger
    associatedtype TAccountId: AccountId
    associatedtype TAddress: Address<TAccountId>
    associatedtype TSignature: Signature
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & ValidatableType
    associatedtype TSystemProperties: SystemProperties
    associatedtype TRuntimeVersion: RuntimeVersion
    associatedtype TRuntimeDispatchInfo: RuntimeDynamicDecodable & ValidatableType
    associatedtype TFeeDetails: RuntimeDynamicDecodable & ValidatableType
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
    
    // Parse and return dynamic types from metadata
    func dynamicTypes(metadata: any Metadata) throws -> DynamicTypes
    
    // Extrinsic manager factory method
    func extrinsicManager(types: DynamicTypes,
                          metadata: any Metadata) throws -> TExtrinsicManager
    
    // Metadata calls. Should be fully static
    func metadataVersionsCall() throws -> any StaticCodableRuntimeCall<[UInt32]>
    func metadataAtVersionCall(
        version: UInt32
    ) throws -> any StaticCodableRuntimeCall<Optional<OpaqueMetadata>>
    
    // Custom coders for dynamic coding. Usefull when type definition isn't equal to encoding
    func customCoders(types: DynamicTypes,
                      metadata: any Metadata) throws -> [RuntimeCustomDynamicCoder]
    
    // Storage key for Events
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents>
    
    // Info Calls
    func queryInfoCall(extrinsic: Data,
                       runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.RuntimeDispatchInfo>
    func queryFeeDetailsCall(extrinsic: Data,
                             runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.FeeDetails>
    
    // Provides default value for payment
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment
    
    // Pallets list for validation
    func frames(runtime: any Runtime) throws -> [RuntimeValidatableType]
    // Runtime calls for validation
    func runtimeCalls(runtime: any Runtime) throws -> [any StaticRuntimeCall.Type]
    
    // If you want your own Scale Codec coders
    func encoder() -> ScaleCodec.Encoder
    func encoder(reservedCapacity count: Int) -> ScaleCodec.Encoder
    func decoder(data: Data) -> ScaleCodec.Decoder
}

// Config that supports batches
public protocol BatchSupportedConfig: Config {
    associatedtype TBatchCall: SomeBatchCall
    associatedtype TBatchAllCall: SomeBatchCall
    
    // Checks is batch supported dynamically
    func isBatchSupported(types: DynamicTypes,
                          metadata: any Metadata) -> Bool
    
    // Batch calls for validation
    static var batchCalls: [any SomeBatchCall.Type] { get }
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
    func isBatchSupported(types: DynamicTypes,
                          metadata: any Metadata) -> Bool
    {
        metadata.resolve(pallet: TBatchCall.pallet)?.callIndex(name: TBatchCall.name) != nil &&
        metadata.resolve(pallet: TBatchAllCall.pallet)?.callIndex(name: TBatchAllCall.name) != nil
    }
    
    @inlinable
    static var batchCalls: [any SomeBatchCall.Type] { [TBatchCall.self, TBatchAllCall.self] }
}

// namespace for Configs declaration
@frozen public struct Configs {
    // Type for Config registrations. Provides better constructors for Api
    @frozen public struct Registry<C: Config> {
        public let config: C
        @inlinable public init(config: C) { self.config = config }
    }
    
    private init() {}
    
    public static var defaultCustomCoders: [RuntimeCustomDynamicCoder] = [
        ExtrinsicCustomDynamicCoder(name: "UncheckedExtrinsic")
    ]
    
    @inlinable
    public static func defaultFrames<C: Config>(_: C.Type) -> [any RuntimeValidatableType]
    {
        [BaseSystemFrame<C>()]
    }
    
    @inlinable
    public static func defaultRuntimeCalls<C: Config>(
        runtime: any Runtime, config: C
    ) -> [any StaticRuntimeCall.Type] {
        runtime.metadata.version < 15
            ? []
            : [TransactionQueryInfoRuntimeCall<ST<C>.RuntimeDispatchInfo>.self,
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
    func customCoders(types: DynamicTypes,
                      metadata: any Metadata) throws -> [RuntimeCustomDynamicCoder]
    {
        Configs.defaultCustomCoders
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
    func frames(runtime: any Runtime) throws -> [RuntimeValidatableType] {
        Configs.defaultFrames(Self.self)
    }
    
    @inlinable
    func runtimeCalls(runtime: any Runtime) throws -> [any StaticRuntimeCall.Type] {
        Configs.defaultRuntimeCalls(runtime: runtime, config: self)
    }
    
    @inlinable
    func dynamicTypes(metadata: any Metadata) throws -> DynamicTypes {
        try .tryParse(
            from: metadata, block: ST<Self>.Block.self,
            blockEvents: ST<Self>.BlockEvents.self,
            blockEventsKey: (EventsStorageKey<ST<Self>.BlockEvents>.name,
                             EventsStorageKey<ST<Self>.BlockEvents>.pallet)
        )
    }
}

public extension Config where ST<Self>.ExtrinsicPayment: Default {
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment {
        .default
    }
}
