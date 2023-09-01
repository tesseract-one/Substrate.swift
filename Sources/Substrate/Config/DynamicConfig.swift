//
//  DynamicRuntime.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import ContextCodable
import Serializable

public extension Configs {
    struct BaseDynamic: BasicConfig {
        public typealias THasher = AnyFixedHasher
        public typealias TIndex = UInt256
        public typealias TAccountId = AccountId32
        public typealias TAddress =  AnyAddress<TAccountId>
        public typealias TSignature = AnySignature
        public typealias TExtrinsicEra = ExtrinsicEra
        public typealias TExtrinsicPayment = Value<Void>
        public typealias TSystemProperties = AnySystemProperties
        public typealias TRuntimeVersion = AnyRuntimeVersion<UInt32>
        public typealias TFeeDetails = Value<RuntimeType.Id>
        public typealias TRuntimeDispatchInfo = Value<RuntimeType.Id>
    }
    
    struct Dynamic: Config, BatchSupportedConfig {
        public typealias BC = BaseDynamic
        
        public typealias TBlock = AnyBlock<BC.THasher, BC.TIndex, BlockExtrinsic<TExtrinsicManager>>
        public typealias TChainBlock = AnyChainBlock<TBlock>
        public typealias TExtrinsicManager = ExtrinsicV4Manager<DynamicSignedExtensionsProvider<BC>>
        public typealias TTransactionStatus = TransactionStatus<BC.THasher.THash, BC.THasher.THash>
        public typealias TDispatchError = AnyDispatchError
        public typealias TTransactionValidityError = AnyTransactionValidityError
        public typealias TExtrinsicFailureEvent = AnyExtrinsicFailureEvent
        public typealias TBlockEvents = BlockEvents<AnyEventRecord>
        public typealias TStorageChangeSet = StorageChangeSet<BC.THasher.THash>
        
        public typealias TBatchCall = BatchCall
        public typealias TBatchAllCall = BatchAllCall
        
        public let extensions: [DynamicExtrinsicExtension]
        public let runtimeCustomCoders: [RuntimeCustomDynamicCoder]
        public let payment: ST<Self>.ExtrinsicPayment?
        public let blockSelector: NSRegularExpression
        public let headerSelector: NSRegularExpression
        public let accountSelector: NSRegularExpression
        public let dispatchErrorSelector: NSRegularExpression
        public let transactionValidityErrorSelector: NSRegularExpression
        
        public init(extensions: [DynamicExtrinsicExtension] = Configs.dynamicSignedExtensions,
                    customCoders: [RuntimeCustomDynamicCoder] = Configs.customCoders,
                    defaultPayment: ST<Self>.ExtrinsicPayment? = nil,
                    blockSelector: String = "^.*Block$",
                    headerSelector: String = "^.*Header$",
                    accountSelector: String = "^.*AccountId[0-9]*$",
                    dispatchErrorSelector: String = "^.*DispatchError$",
                    transactionValidityErrorSelector: String = "^.*TransactionValidityError$") throws
        {
            self.extensions = extensions
            self.runtimeCustomCoders = customCoders
            self.payment = defaultPayment
            self.blockSelector = try NSRegularExpression(pattern: blockSelector)
            self.accountSelector = try NSRegularExpression(pattern: accountSelector)
            self.headerSelector = try NSRegularExpression(pattern: headerSelector)
            self.dispatchErrorSelector = try NSRegularExpression(pattern: dispatchErrorSelector)
            self.transactionValidityErrorSelector = try NSRegularExpression(
                pattern: transactionValidityErrorSelector
            )
        }
    }
    
    static var dynamicSignedExtensions: [any DynamicExtrinsicExtension] = [
        DynamicCheckSpecVersionExtension(),
        DynamicCheckTxVersionExtension(),
        DynamicCheckGenesisExtension(),
        DynamicCheckNonZeroSenderExtension(),
        DynamicCheckNonceExtension(),
        DynamicCheckMortalityExtension(),
        DynamicCheckWeightExtension(),
        DynamicChargeTransactionPaymentExtension(),
        DynamicPrevalidateAttestsExtension()
    ]
    
    static var customCoders: [RuntimeCustomDynamicCoder] = [
        ExtrinsicCustomDynamicCoder(name: "UncheckedExtrinsic")
    ]
}

// Object getters and properties
public extension Configs.Dynamic {
    @inlinable
    func extrinsicManager() throws -> TExtrinsicManager {
        let provider = DynamicSignedExtensionsProvider<SBC<Self>>(
            extensions: extensions, version: ST<Self>.ExtrinsicManager.version
        )
        return TExtrinsicManager(extensions: provider)
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
            throw ConfigTypeLookupError.typeNotFound(name: "Header",
                                                     selector: headerSelector.pattern)
        }
        return type
    }
    
    func hashType(metadata: any Metadata) throws -> RuntimeType.Info {
        let header = try headerType(metadata: metadata)
        guard case .composite(let fields) = header.type.definition else {
            throw ConfigTypeLookupError.badHeaderType(header: header)
        }
        let hashType = fields.first { $0.typeName?.lowercased().contains("hash") ?? false }?.type
        guard let hashType = hashType, let hashInfo = metadata.resolve(type: hashType) else {
            throw ConfigTypeLookupError.hashTypeNotFound
        }
        return RuntimeType.Info(id: hashType, type: hashInfo)
    }
    
    func hasher(metadata: Metadata) throws -> ST<Self>.Hasher {
        let header = try headerType(metadata: metadata)
        let hashType = header.type.parameters.first { $0.name.lowercased() == "hash" }?.type
        guard let hashType = hashType, let hashName = metadata.resolve(type: hashType)?.path.last else {
            throw ConfigTypeLookupError.hashTypeNotFound
        }
        guard let hasher = AnyFixedHasher(name: hashName) else {
            throw ConfigTypeLookupError.unknownHashName(hashName)
        }
        return hasher
    }
    
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment {
        if let def = payment { return def }
        guard let type = DynamicChargeTransactionPaymentExtension.tipType(runtime: runtime) else {
            throw ConfigTypeLookupError.paymentTypeNotFound
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
        default: throw ConfigTypeLookupError.cantProvideDefaultPayment(forType: type)
        }
    }
}

// Type lookups
public extension Configs.Dynamic {
    func blockType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: { blockSelector.matches($0) }) else {
            throw ConfigTypeLookupError.typeNotFound(name: "Block", selector:
                                                     blockSelector.pattern)
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
            throw ConfigTypeLookupError.typeNotFound(name: "AccountId",
                                                     selector: accountSelector.pattern)
        }
        return type
    }
    
    func dispatchErrorType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: {dispatchErrorSelector.matches($0)}) else {
            throw ConfigTypeLookupError.typeNotFound(name: "DispatchError",
                                                     selector: dispatchErrorSelector.pattern)
        }
        return type
    }
    
    func transactionValidityErrorType(metadata: any Metadata) throws -> RuntimeType.Info {
        guard let type = metadata.search(type: {transactionValidityErrorSelector.matches($0)}) else {
            throw ConfigTypeLookupError.typeNotFound(name: "TransactionValidityError",
                                                     selector: transactionValidityErrorSelector.pattern)
        }
        return type
    }
}

// ConfigRegistry helpers
public extension Configs.Registry where C == Configs.Dynamic, Ext == Void {
    @inlinable
    static func dynamic(extensions: [DynamicExtrinsicExtension] = Configs.dynamicSignedExtensions,
                        customCoders: [RuntimeCustomDynamicCoder] = Configs.customCoders,
                        defaultPayment: ST<C>.ExtrinsicPayment? = nil,
                        blockSelector: String = "^.*Block$",
                        headerSelector: String = "^.*Header$",
                        accountSelector: String = "^.*AccountId[0-9]*$",
                        dispatchErrorSelector: String = "^.*DispatchError$",
                        transactionValidityErrorSelector: String = "^.*TransactionValidityError$"
    ) throws -> Self {
        let config = try Configs.Dynamic(extensions: extensions, customCoders: customCoders,
                                         defaultPayment: defaultPayment,
                                         blockSelector: blockSelector,
                                         headerSelector: headerSelector,
                                         accountSelector: accountSelector,
                                         dispatchErrorSelector: dispatchErrorSelector,
                                         transactionValidityErrorSelector: transactionValidityErrorSelector)
        return Self(config: config)
    }

    @inlinable static var dynamic: Self { try! dynamic() }
}
