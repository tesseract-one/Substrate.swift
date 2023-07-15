//
//  DynamicRuntime.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import Serializable

public struct DynamicConfig: Config {
    public typealias THasher = AnyFixedHasher
    public typealias TIndex = UInt256
    public typealias TSystemProperties = AnySystemProperties
    public typealias TAccountId = AccountId32
    public typealias TAddress =  AnyAddress<TAccountId>
    public typealias TSignature = AnySignature
    public typealias TBlock = AnyBlock<THasher, TIndex, BlockExtrinsic<TExtrinsicManager>>
    public typealias TChainBlock = AnyChainBlock<TBlock, SerializableValue>
    
    public typealias TExtrinsicManager = ExtrinsicV4Manager<Self, DynamicSignedExtensionsProvider<Self>>
    public typealias TTransactionStatus = TransactionStatus<THasher.THash, THasher.THash>
    
    public typealias TExtrinsicEra = ExtrinsicEra
    public typealias TExtrinsicPayment = UInt256
    public typealias TFeeDetails = Value<RuntimeType.Id>
    public typealias TDispatchInfo = Value<RuntimeType.Id>
    public typealias TDispatchError = AnyDispatchError
    public typealias TTransactionValidityError = AnyTransactionValidityError
    public typealias TExtrinsicFailureEvent = AnyExtrinsicFailureEvent
    public typealias TBlockEvents = BlockEvents<EventRecord<THasher.THash>>
    public typealias TRuntimeVersion = AnyRuntimeVersion
    public typealias TStorageChangeSet = StorageChangeSet<THasher.THash>
    
    public enum Error: Swift.Error {
        case typeNotFound(name: String, selector: NSRegularExpression)
        case hashTypeNotFound(header: RuntimeType.Info)
        case eventTypeNotFound(record: RuntimeType.Info)
        case extrinsicInfoNotFound
        case unknownHashName(String)
    }
    
    public let extrinsicExtensions: [DynamicExtrinsicExtension]
    public let blockSelector: NSRegularExpression
    public let headerSelector: NSRegularExpression
    public let accountSelector: NSRegularExpression
    public let dispatchInfoSelector: NSRegularExpression
    public let dispatchErrorSelector: NSRegularExpression
    public let transactionValidityErrorSelector: NSRegularExpression
    public let feeDetailsSelector: NSRegularExpression
    public let eventRecordSelector: NSRegularExpression
    
    public init(extrinsicExtensions: [DynamicExtrinsicExtension] = Self.allExtensions,
                blockSelector: String = "^.*Block$",
                headerSelector: String = "^.*Header$",
                accountSelector: String = "^.*AccountId[0-9]*$",
                dispatchInfoSelector: String = "^.*DispatchInfo$",
                dispatchErrorSelector: String = "^.*DispatchError$",
                transactionValidityErrorSelector: String = "^.*TransactionValidityError$",
                feeDetailsSelector: String = "^.*FeeDetails$",
                eventRecordSelector: String = "^.*EventRecord$") throws
    {
        self.extrinsicExtensions = extrinsicExtensions
        self.blockSelector = try NSRegularExpression(pattern: blockSelector)
        self.accountSelector = try NSRegularExpression(pattern: accountSelector)
        self.headerSelector = try NSRegularExpression(pattern: headerSelector)
        self.dispatchInfoSelector = try NSRegularExpression(pattern: dispatchInfoSelector)
        self.dispatchErrorSelector = try NSRegularExpression(pattern: dispatchErrorSelector)
        self.transactionValidityErrorSelector = try NSRegularExpression(
            pattern: transactionValidityErrorSelector
        )
        self.feeDetailsSelector = try NSRegularExpression(pattern: feeDetailsSelector)
        self.eventRecordSelector = try NSRegularExpression(pattern: eventRecordSelector)
    }
}

extension DynamicConfig: BatchSupportedConfig {
    public typealias TBatchCall = AnyBatchCall
    public typealias TBatchAllCall = AnyBatchAllCall
}

// Object getters and properties
public extension DynamicConfig {
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents> {
        AnyStorageKey(name: "Events", pallet: "System", path: [])
    }
    
    func metadataVersionsCall() throws -> any StaticCodableRuntimeCall<[UInt32]> {
        MetadataVersionsRuntimeCall()
    }
    
    func metadataAtVersionCall(version: UInt32) throws -> any StaticCodableRuntimeCall<Optional<OpaqueMetadata>> {
        MetadataAtVersionRuntimeCall(version: version)
    }
    
    func queryInfoCall(extrinsic: Data, runtime: any Runtime) throws -> any RuntimeCall<TDispatchInfo> {
//        AnyRuntimeCall(api: "TransactionPaymentApi",
//                       method: "query_info",
//                       params: [extrinsic, extrinsic.count])
        TransactionInfoCall(method: "query_info", extrinsic: extrinsic)
    }
    
    func queryFeeDetailsCall(extrinsic: Data, runtime: any Runtime) throws -> any RuntimeCall<TFeeDetails> {
//        AnyRuntimeCall(api: "TransactionPaymentApi",
//                       method: "query_fee_details",
//                       params: [extrinsic, extrinsic.count])
        TransactionInfoCall(method: "query_fee_details", extrinsic: extrinsic)
    }
    
    func extrinsicManager() throws -> TExtrinsicManager {
        let provider = DynamicSignedExtensionsProvider<Self>(extensions: extrinsicExtensions,
                                                             version: TExtrinsicManager.version)
        return TExtrinsicManager(extensions: provider)
    }
    
    func hasher(metadata: Metadata) throws -> AnyFixedHasher {
        var header: RuntimeType.Info? = nil
        if let block = try? blockType(metadata: metadata) {
            let headerType = block.type.parameters.first{ $0.name.lowercased() == "header" }?.type
            if let id = headerType, let type = metadata.resolve(type: id) {
                header = RuntimeType.Info(id: id, type: type)
            }
        }
        if header == nil {
            guard let type = metadata.search(type: { headerSelector.matches($0) }) else {
                throw Error.typeNotFound(name: "Header", selector: headerSelector)
            }
            header = type
        }
        let hashType = header!.type.parameters.first { $0.name.lowercased() == "hash" }?.type
        guard let hashType = hashType, let hashName = metadata.resolve(type: hashType)?.path.last else {
            throw Error.hashTypeNotFound(header: header!)
        }
        guard let hasher = AnyFixedHasher(name: hashName) else {
            throw Error.unknownHashName(hashName)
        }
        return hasher
    }
    
    static let allExtensions: [DynamicExtrinsicExtension] = [
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

// Type lookups
public extension DynamicConfig {
    func blockType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: { blockSelector.matches($0) }) else {
            throw Error.typeNotFound(name: "Block", selector: blockSelector)
        }
        return type
    }
    
    func extrinsicTypes(
        metadata: Metadata
    ) throws -> (call: RuntimeType.Info, addr: RuntimeType.Info,
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
            throw Error.extrinsicInfoNotFound
        }
        return (call: RuntimeType.Info(id: callTypeId, type: callType),
                addr: RuntimeType.Info(id: addressTypeId, type: addressType),
                signature: RuntimeType.Info(id: sigTypeId, type: sigType),
                extra: RuntimeType.Info(id: extraTypeId, type: extraType))
    }
    
    func accountType(metadata: any Metadata,
                     address: RuntimeType.Info) throws -> RuntimeType.Info
    {
        let selectors = ["accountid", "t::accountid", "account", "acc", "a"]
        let accid = address.type.parameters.first{selectors.contains($0.name.lowercased())}?.type
        if let id = accid, let info = metadata.resolve(type: id) {
            return RuntimeType.Info(id: id, type: info)
        }
        guard let type = metadata.search(type: {accountSelector.matches($0)}) else {
            throw Error.typeNotFound(name: "AccountId", selector: dispatchInfoSelector)
        }
        return type
    }
    
    func dispatchInfoType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: {dispatchInfoSelector.matches($0)}) else {
            throw Error.typeNotFound(name: "DispatchInfo", selector: dispatchInfoSelector)
        }
        return type
    }
    
    func dispatchErrorType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: {dispatchErrorSelector.matches($0)}) else {
            throw Error.typeNotFound(name: "DispatchError", selector: dispatchErrorSelector)
        }
        return type
    }
    
    func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: {transactionValidityErrorSelector.matches($0)}) else {
            throw Error.typeNotFound(name: "TransactionValidityError",
                                     selector: transactionValidityErrorSelector)
        }
        return type
    }
    
    func feeDetailsType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: {feeDetailsSelector.matches($0)}) else {
            throw Error.typeNotFound(name: "FeeDetails", selector: feeDetailsSelector)
        }
        return type
    }
    
    func eventType(metadata: Metadata) throws -> RuntimeType.Info {
        guard let record = metadata.search(type: {eventRecordSelector.matches($0)}) else {
            throw Error.typeNotFound(name: "EventRecord", selector: eventRecordSelector)
        }
        let eventNames = ["e", "ev", "event", "t::event"]
        guard let field = record.type.parameters.first(where: {
            eventNames.contains($0.name.lowercased())
        })?.type else {
            throw Error.eventTypeNotFound(record: record)
        }
        return RuntimeType.Info(id: field, type: metadata.resolve(type: field)!)
    }
}

// ConfigRegistry helpers
public extension ConfigRegistry where C == DynamicConfig {
    @inlinable
    static func dynamic(extrinsicExtensions: [DynamicExtrinsicExtension] = DynamicConfig.allExtensions,
                        blockSelector: String = "^.*Block$",
                        headerSelector: String = "^.*Header$",
                        accountSelector: String = "^.*AccountId[0-9]*$",
                        dispatchInfoSelector: String = "^.*DispatchInfo$",
                        dispatchErrorSelector: String = "^.*DispatchError$",
                        transactionValidityErrorSelector: String = "^.*TransactionValidityError$",
                        feeDetailsSelector: String = "^.*FeeDetails$",
                        eventRecordSelector: String = "^.*EventRecord$") throws -> Self {
        let config = try DynamicConfig(
            extrinsicExtensions: extrinsicExtensions, blockSelector: blockSelector,
            headerSelector: headerSelector, accountSelector: accountSelector,
            dispatchInfoSelector: dispatchInfoSelector, dispatchErrorSelector: dispatchErrorSelector,
            transactionValidityErrorSelector: transactionValidityErrorSelector,
            feeDetailsSelector: feeDetailsSelector, eventRecordSelector: eventRecordSelector
        )
        return Self(config: config)
    }
    
    @inlinable static var dynamic: Self { try! dynamic() }
}

// This is workaround for bad QueryInfo calls metadata
// Should be removed when fixed: https://github.com/paritytech/substrate/issues/14584
public extension DynamicConfig {
    struct TransactionInfoCall<Return: RuntimeDynamicDecodable>: RuntimeCall {
        public typealias TReturn = Return
        
        public var api: String { "TransactionPaymentApi" }
        public let method: String
        public let extrinsic: Data
        
        public init(method: String, extrinsic: Data) {
            self.method = method
            self.extrinsic = extrinsic
        }
        
        public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
            try encoder.encode(extrinsic, .fixed(UInt(extrinsic.count)))
            try encoder.encode(UInt32(extrinsic.count))
        }
        
        public func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> Return {
            return try Return(from: &decoder, runtime: runtime) { runtime in
                guard let call = runtime.resolve(runtimeCall: method, api: api) else {
                    throw RuntimeCallCodingError.callNotFound(method: method, api: api)
                }
                return call.result.id
            }
        }
    }
}
