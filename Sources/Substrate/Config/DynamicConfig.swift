//
//  DynamicRuntime.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import Serializable

public struct DynamicConfig: Config {
    public typealias THasher = AnyFixedHasher
    public typealias TIndex = UInt256
    public typealias TSystemProperties = AnySystemProperties
    public typealias TAccountId = AccountId32
    public typealias TAddress =  AnyAddress<TAccountId>
    public typealias TSignature = AnySignature
    public typealias TBlock = AnyBlock<THasher, TIndex, BlockExtrinsic<TExtrinsicManager>>
    public typealias TChainBlock = AnyChainBlock<TBlock>
    
    public typealias TExtrinsicManager = ExtrinsicV4Manager<Self, DynamicSignedExtensionsProvider<Self>>
    public typealias TTransactionStatus = TransactionStatus<THasher.THash, THasher.THash>
    
    public typealias TExtrinsicEra = ExtrinsicEra
    public typealias TExtrinsicPayment = Value<Void>
    public typealias TFeeDetails = Value<RuntimeType.Id>
    public typealias TDispatchInfo = Value<RuntimeType.Id>
    public typealias TDispatchError = AnyDispatchError
    public typealias TTransactionValidityError = AnyTransactionValidityError
    public typealias TExtrinsicFailureEvent = AnyExtrinsicFailureEvent
    public typealias TBlockEvents = BlockEvents<AnyEventRecord>
    public typealias TRuntimeVersion = AnyRuntimeVersion
    public typealias TStorageChangeSet = StorageChangeSet<THasher.THash>
    
    public enum Error: Swift.Error {
        case typeNotFound(name: String, selector: NSRegularExpression)
        case hashTypeNotFound(header: RuntimeType.Info)
        case badHeaderType(header: RuntimeType.Info)
        case paymentTypeNotFound
        case cantProvideDefaultPayment(forType: RuntimeType.Info)
        case extrinsicInfoNotFound
        case unknownHashName(String)
    }
    
    public let extrinsicExtensions: [DynamicExtrinsicExtension]
    public let runtimeCustomCoders: [RuntimeCustomDynamicCoder]
    public let payment: TExtrinsicPayment?
    public let blockSelector: NSRegularExpression
    public let headerSelector: NSRegularExpression
    public let accountSelector: NSRegularExpression
    public let dispatchInfoSelector: NSRegularExpression
    public let dispatchErrorSelector: NSRegularExpression
    public let transactionValidityErrorSelector: NSRegularExpression
    public let feeDetailsSelector: NSRegularExpression
    
    public init(extrinsicExtensions: [DynamicExtrinsicExtension] = Self.allExtensions,
                customCoders: [RuntimeCustomDynamicCoder] = Self.customCoders,
                defaultPayment: TExtrinsicPayment? = nil,
                blockSelector: String = "^.*Block$",
                headerSelector: String = "^.*Header$",
                accountSelector: String = "^.*AccountId[0-9]*$",
                dispatchInfoSelector: String = "^.*DispatchInfo$",
                dispatchErrorSelector: String = "^.*DispatchError$",
                transactionValidityErrorSelector: String = "^.*TransactionValidityError$",
                feeDetailsSelector: String = "^.*FeeDetails$") throws
    {
        self.extrinsicExtensions = extrinsicExtensions
        self.runtimeCustomCoders = customCoders
        self.payment = defaultPayment
        self.blockSelector = try NSRegularExpression(pattern: blockSelector)
        self.accountSelector = try NSRegularExpression(pattern: accountSelector)
        self.headerSelector = try NSRegularExpression(pattern: headerSelector)
        self.dispatchInfoSelector = try NSRegularExpression(pattern: dispatchInfoSelector)
        self.dispatchErrorSelector = try NSRegularExpression(pattern: dispatchErrorSelector)
        self.transactionValidityErrorSelector = try NSRegularExpression(
            pattern: transactionValidityErrorSelector
        )
        self.feeDetailsSelector = try NSRegularExpression(pattern: feeDetailsSelector)
    }
}

extension DynamicConfig: BatchSupportedConfig {
    public typealias TBatchCall = BatchCall
    public typealias TBatchAllCall = BatchAllCall
}

// Object getters and properties
public extension DynamicConfig {
    @inlinable
    func extrinsicManager() throws -> TExtrinsicManager {
        let provider = DynamicSignedExtensionsProvider<Self>(extensions: extrinsicExtensions,
                                                             version: TExtrinsicManager.version)
        return TExtrinsicManager(extensions: provider)
    }
    
    @inlinable
    func eventsStorageKey(runtime: any Runtime) throws -> any StorageKey<TBlockEvents> {
        AnyStorageKey(name: "Events", pallet: "System", path: [])
    }
    
    @inlinable
    func queryInfoCall(extrinsic: Data, runtime: any Runtime) throws -> any RuntimeCall<TDispatchInfo> {
        AnyRuntimeCall(api: "TransactionPaymentApi",
                       method: "query_info",
                       params: [extrinsic, extrinsic.count])
    }
    
    @inlinable
    func queryFeeDetailsCall(extrinsic: Data, runtime: any Runtime) throws -> any RuntimeCall<TFeeDetails> {
        AnyRuntimeCall(api: "TransactionPaymentApi",
                       method: "query_fee_details",
                       params: [extrinsic, extrinsic.count])
    }
    
    @inlinable
    func customCoders() throws -> [RuntimeCustomDynamicCoder] { runtimeCustomCoders }
    
    func headerType(metadata: any Metadata) throws -> RuntimeType.Info {
        if let block = try? blockType(metadata: metadata) {
            let headerType = block.type.parameters.first{ $0.name.lowercased() == "header" }?.type
            if let id = headerType, let type = metadata.resolve(type: id) {
                return RuntimeType.Info(id: id, type: type)
            }
        }
        guard let type = metadata.search(type: { headerSelector.matches($0) }) else {
            throw Error.typeNotFound(name: "Header", selector: headerSelector)
        }
        return type
    }
    
    func hashType(metadata: any Metadata) throws -> RuntimeType.Info {
        let header = try headerType(metadata: metadata)
        guard case .composite(let fields) = header.type.definition else {
            throw Error.badHeaderType(header: header)
        }
        let hashType = fields.first { $0.typeName?.lowercased().contains("hash") ?? false }?.type
        guard let hashType = hashType, let hashInfo = metadata.resolve(type: hashType) else {
            throw Error.hashTypeNotFound(header: header)
        }
        return RuntimeType.Info(id: hashType, type: hashInfo)
    }
    
    func hasher(metadata: Metadata) throws -> AnyFixedHasher {
        let header = try headerType(metadata: metadata)
        let hashType = header.type.parameters.first { $0.name.lowercased() == "hash" }?.type
        guard let hashType = hashType, let hashName = metadata.resolve(type: hashType)?.path.last else {
            throw Error.hashTypeNotFound(header: header)
        }
        guard let hasher = AnyFixedHasher(name: hashName) else {
            throw Error.unknownHashName(hashName)
        }
        return hasher
    }
    
    func defaultPayment(runtime: any Runtime) throws -> TExtrinsicPayment {
        if let def = payment { return def }
        guard let type = DynamicChargeTransactionPaymentExtension<Self>.tipType(runtime: runtime) else {
            throw Error.paymentTypeNotFound
        }
        switch type.type.flatten(runtime).definition {
        case .compact(of: _): return .uint(.default)
        case .primitive(is: let p):
            switch p {
            case .i8, .i16, .i32, .i64, .i128, .i256: return .int(.default)
            case .u8, .u16, .u32, .u64, .u128, .u256: return .uint(.default)
            case .bool: return .bool(.default)
            case .char: return .char(.default)
            case .str: return .string(.default)
            }
        default: throw Error.cantProvideDefaultPayment(forType: type)
        }
    }
    
    static let allExtensions: [DynamicExtrinsicExtension] = [
        DynamicCheckSpecVersionExtension<Self>(),
        DynamicCheckTxVersionExtension<Self>(),
        DynamicCheckGenesisExtension<Self>(),
        DynamicCheckNonZeroSenderExtension<Self>(),
        DynamicCheckNonceExtension<Self>(),
        DynamicCheckMortalityExtension<Self>(),
        DynamicCheckWeightExtension<Self>(),
        DynamicChargeTransactionPaymentExtension<Self>(),
        DynamicPrevalidateAttestsExtension<Self>()
    ]
    
    static let customCoders: [RuntimeCustomDynamicCoder] = [
        ExtrinsicCustomDynamicCoder(name: "UncheckedExtrinsic")
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
                        feeDetailsSelector: String = "^.*FeeDetails$") throws -> Self {
        let config = try DynamicConfig(
            extrinsicExtensions: extrinsicExtensions, blockSelector: blockSelector,
            headerSelector: headerSelector, accountSelector: accountSelector,
            dispatchInfoSelector: dispatchInfoSelector, dispatchErrorSelector: dispatchErrorSelector,
            transactionValidityErrorSelector: transactionValidityErrorSelector,
            feeDetailsSelector: feeDetailsSelector
        )
        return Self(config: config)
    }
    
    @inlinable static var dynamic: Self { try! dynamic() }
}
