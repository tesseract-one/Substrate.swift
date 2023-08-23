//
//  RuntimeConfig.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public typealias ConfigUnsignedInteger = UnsignedInteger & ValueRepresentable & DataConvertible
    & CompactCodable & Swift.Codable & RuntimeCodable & ValidatableRuntimeType

// Config split to avoid recursive types
public protocol BasicConfig {
    associatedtype THasher: FixedHasher
    associatedtype TIndex: ConfigUnsignedInteger
    associatedtype TAccountId: AccountId
    associatedtype TAddress: Address<TAccountId>
    associatedtype TSignature: Signature
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & ValidatableRuntimeType
    associatedtype TSystemProperties: SystemProperties
    associatedtype TRuntimeVersion: RuntimeVersion
    associatedtype TDispatchInfo: RuntimeDynamicDecodable
    associatedtype TFeeDetails: RuntimeDynamicDecodable
}

public protocol Config {
    associatedtype BC: BasicConfig
    
    associatedtype TBlock: SomeBlock where TBlock.THeader.THasher == SBT<BC>.Hasher
    associatedtype TChainBlock: SomeChainBlock<TBlock>
    associatedtype TBlockEvents: SomeBlockEvents
    associatedtype TExtrinsicFailureEvent: SomeExtrinsicFailureEvent
    associatedtype TDispatchError: CallError
    associatedtype TTransactionValidityError: CallError
    associatedtype TTransactionStatus: SomeTransactionStatus<TBlock.THeader.THasher.THash>
    associatedtype TStorageChangeSet: SomeStorageChangeSet<TBlock.THeader.THasher.THash>
    associatedtype TExtrinsicManager: ExtrinsicManager<BC>
    
    // Metadata Info Providers
    func blockType(metadata: any Metadata) throws -> RuntimeType.Info
    func hashType(metadata: any Metadata) throws -> RuntimeType.Info 
    //func dispatchInfoType(metadata: any Metadata) throws -> RuntimeType.Info
//    func feeDetailsType(metadata: any Metadata) throws -> RuntimeType.Info
    func dispatchErrorType(metadata: any Metadata) throws -> RuntimeType.Info
    func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeType.Info
    func accountType(metadata: any Metadata, address: RuntimeType.Info) throws -> RuntimeType.Info
    // Сan be safely removed after removing metadata v14 (v15 has them)
    func extrinsicTypes(metadata: any Metadata) throws -> (call: RuntimeType.Info, addr: RuntimeType.Info,
                                                           signature: RuntimeType.Info, extra: RuntimeType.Info)
    // Object Builders
    func hasher(metadata: any Metadata) throws -> ST<Self>.Hasher
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents>
    func queryInfoCall(extrinsic: Data,
                       runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.DispatchInfo>
    func queryFeeDetailsCall(extrinsic: Data,
                             runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.FeeDetails>
    func metadataVersionsCall() throws -> any StaticCodableRuntimeCall<[UInt32]>
    func metadataAtVersionCall(version: UInt32) throws -> any StaticCodableRuntimeCall<Optional<OpaqueMetadata>>
    func extrinsicManager() throws -> TExtrinsicManager
    func customCoders() throws -> [RuntimeCustomDynamicCoder]
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
    public typealias DispatchInfo = C.TDispatchInfo
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
    public typealias DispatchInfo = SBT<SBC<C>>.DispatchInfo
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
}

// namespace for Configs declaration
@frozen public struct Configs {
    
    // Type for Config registrations. Provides better constructors for Api
    @frozen public struct Registry<C: Config, Ext> {
        public let config: C
        @inlinable public init(config: C) { self.config = config }
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
        [ExtrinsicCustomDynamicCoder(name: "UncheckedExtrinsic")]
    }
    
    @inlinable
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents> {
        EventsStorageKey<TBlockEvents>()
    }
    
    @inlinable
    func queryInfoCall(extrinsic: Data,
                       runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.DispatchInfo> {
        TransactionQueryInfoRuntimeCall(extrinsic: extrinsic)
    }
    
    @inlinable
    func queryFeeDetailsCall(extrinsic: Data,
                             runtime: any Runtime) throws -> any RuntimeCall<ST<Self>.FeeDetails> {
        TransactionQueryFeeDetailsRuntimeCall(extrinsic: extrinsic)
    }
}

// Сan be safely removed after removing metadata v14 (v15 has types inside)
public extension Config {
    func extrinsicTypes(metadata: any Metadata) throws -> (call: RuntimeType.Info, addr: RuntimeType.Info,
                                                           signature: RuntimeType.Info, extra: RuntimeType.Info)
    {
        var addressTypeId: RuntimeType.Id? = nil
        var sigTypeId: RuntimeType.Id? = nil
        var extraTypeId: RuntimeType.Id? = nil
        var callTypeId: RuntimeType.Id? = nil
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
        return (call: RuntimeType.Info(id: callTypeId, type: callType),
                addr: RuntimeType.Info(id: addressTypeId, type: addressType),
                signature: RuntimeType.Info(id: sigTypeId, type: sigType),
                extra: RuntimeType.Info(id: extraTypeId, type: extraType))
    }
}

public extension Config where ST<Self>.Hasher: StaticHasher {
    // Static hasher creates Hash without type lookup
    func hashType(metadata: any Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
    // Static Hasher can be returned by singleton instance
    func hasher(metadata: Metadata) throws -> ST<Self>.Hasher { ST<Self>.Hasher.instance }
}

// Static Block doesn't need runtime type
public extension Config where TBlock: StaticBlock {
    func blockType(metadata: Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

// Static Transaction Validity Error doesn't need runtime type
public extension Config where TTransactionValidityError: StaticCallError {
    func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

// Static Dispatch Error doesn't need runtime type
public extension Config where TDispatchError: StaticCallError {
    func dispatchErrorType(metadata: any Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

// Static Dispatch Info doesn't need runtime type
public extension Config where ST<Self>.DispatchInfo: RuntimeDecodable {
    func dispatchInfoType(metadata: any Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

// Static Fee Details doesn't need runtime type
public extension Config where ST<Self>.FeeDetails: RuntimeDecodable {
    func feeDetailsType(metadata: any Metadata) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

// Static Account doesn't need runtime type
public extension Config where ST<Self>.AccountId: StaticAccountId {
    func accountType(metadata: any Metadata, address: RuntimeType.Info) throws -> RuntimeType.Info {
        throw RuntimeType.IdNeverCalledError()
    }
}

public extension Config where ST<Self>.ExtrinsicPayment: Default {
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment {
        .default
    }
}

public enum ConfigTypeLookupError: Error {
    case paymentTypeNotFound
    case accountTypeNotFound
    case extrinsicTypesNotFound
    
    case typeNotFound(name: String, selector: NSRegularExpression)
    case hashTypeNotFound
    case badHeaderType(header: RuntimeType.Info)
    
    case cantProvideDefaultPayment(forType: RuntimeType.Info)
    case extrinsicInfoNotFound
    case unknownHashName(String)
}
