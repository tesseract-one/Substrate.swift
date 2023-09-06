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
    struct BaseDynamic<A: AccountId, H: FixedHasher>: BasicConfig {
        public typealias THasher = H
        public typealias TIndex = UInt256
        public typealias TAccountId = A
        public typealias TAddress =  AnyAddress<TAccountId>
        public typealias TSignature = AnySignature
        public typealias TExtrinsicEra = ExtrinsicEra
        public typealias TExtrinsicPayment = Value<Void>
        public typealias TSystemProperties = AnySystemProperties
        public typealias TRuntimeVersion = AnyRuntimeVersion<UInt32>
        public typealias TFeeDetails = Value<NetworkType.Id>
        public typealias TRuntimeDispatchInfo = Value<NetworkType.Id>
    }
    
    struct Dynamic<A: AccountId, H: FixedHasher>: Config, BatchSupportedConfig {
        public typealias BC = BaseDynamic<A, H>
        
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
                    customCoders: [RuntimeCustomDynamicCoder] = Configs.defaultCustomCoders,
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
}

// Object getters and properties
public extension Configs.Dynamic {
    @inlinable
    func extrinsicManager(types: DynamicTypes,
                          metadata: any Metadata) throws -> TExtrinsicManager
    {
        let provider = DynamicSignedExtensionsProvider<SBC<Self>>(
            extensions: extensions, version: ST<Self>.ExtrinsicManager.version
        )
        return TExtrinsicManager(extensions: provider)
    }
    
    @inlinable
    func customCoders(types: DynamicTypes,
                      metadata: any Metadata) throws -> [RuntimeCustomDynamicCoder]
    {
        runtimeCustomCoders
    }
    
    @inlinable
    func dynamicTypes(metadata: any Metadata) throws -> DynamicTypes {
        try .tryParse(
            from: metadata, block: ST<Self>.Block.self,
            blockEvents: ST<Self>.BlockEvents.self,
            blockEventsKey: (EventsStorageKey<ST<Self>.BlockEvents>.name,
                             EventsStorageKey<ST<Self>.BlockEvents>.pallet),
            accountSelector: accountSelector, blockSelector: blockSelector,
            headerSelector: headerSelector, dispatchErrorSelector: dispatchErrorSelector,
            transactionValidityErrorSelector: transactionValidityErrorSelector
        )
    }
    
    func defaultPayment(runtime: any Runtime) throws -> ST<Self>.ExtrinsicPayment {
        if let def = payment { return def }
        guard let type = DynamicChargeTransactionPaymentExtension.tipType(runtime: runtime) else {
            throw DynamicTypes.LookupError.typeNotFound(
                name: "Tip",
                selector: ExtrinsicExtensionId.chargeTransactionPayment.rawValue
            )
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
        default:
            throw DynamicTypes.LookupError.wrongType(name: type.description,
                                                           reason: "Can't provide default value")
        }
    }
}

// ConfigRegistry helpers
public extension Configs.Registry {
    @inlinable
    static func dynamic<H: FixedHasher, A: AccountId>(
        account: A.Type, hasher: H.Type,
        extensions: [DynamicExtrinsicExtension] = Configs.dynamicSignedExtensions,
        customCoders: [RuntimeCustomDynamicCoder] = Configs.defaultCustomCoders,
        defaultPayment: ST<Configs.Dynamic<A, H>>.ExtrinsicPayment? = nil,
        blockSelector: String = "^.*Block$", headerSelector: String = "^.*Header$",
        accountSelector: String = "^.*AccountId[0-9]*$",
        dispatchErrorSelector: String = "^.*DispatchError$",
        transactionValidityErrorSelector: String = "^.*TransactionValidityError$"
    ) throws -> Configs.Registry<Configs.Dynamic<A, H>> {
        let config = try Configs.Dynamic<A, H>(
            extensions: extensions, customCoders: customCoders,
            defaultPayment: defaultPayment, blockSelector: blockSelector,
            headerSelector: headerSelector, accountSelector: accountSelector,
            dispatchErrorSelector: dispatchErrorSelector,
            transactionValidityErrorSelector: transactionValidityErrorSelector)
        return Configs.Registry(config: config)
    }
}

public extension Configs.Registry where C == Configs.Dynamic<AccountId32, HBlake2b256> {
    @inlinable static var dynamicBlake2: Self { try! dynamic(account: AccountId32.self,
                                                             hasher: HBlake2b256.self) }
}

public extension Configs.Registry where C == Configs.Dynamic<AccountId32, AnyFixedHasher> {
    @inlinable static var dynamicAnyHasher: Self { try! dynamic(account: AccountId32.self,
                                                                hasher: AnyFixedHasher.self) }
}
