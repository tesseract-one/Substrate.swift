//
//  SubstrateConfig.swift
//
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec
import Tuples

public extension Configs {
    struct BaseSubstrate: BasicConfig {
        public typealias THasher = HBlake2b256
        public typealias TIndex = UInt32
        public typealias TAccountId = AccountId32
        public typealias Balance = UInt128
        public typealias TAddress = MultiAddress<TAccountId, TIndex>
        public typealias TSignature = MultiSignature
        public typealias TExtrinsicEra = ExtrinsicEra
        public typealias TExtrinsicPayment = Compact<Balance>
        public typealias TRuntimeDispatchInfo = RuntimeDispatchInfo<Balance>
        public typealias TFeeDetails = FeeDetails<Balance>
        public typealias TSystemProperties = AnySystemProperties
        public typealias TRuntimeVersion = AnyRuntimeVersion<UInt32>
    }
    
    struct Substrate: Config {
        public typealias BC = BaseSubstrate

        public typealias TBlock = SubstrateBlock<BC.THasher, BC.TIndex, BlockExtrinsic<TExtrinsicManager>>
        public typealias TChainBlock = SubstrateChainBlock<TBlock>
        public typealias TBlockEvents = BlockEvents<EventRecord<BC.THasher.THash>>
        public typealias TExtrinsicFailureEvent = ExtrinsicFailureEvent
        public typealias TDispatchError = DispatchError
        public typealias TTransactionValidityError = TransactionValidityError
        public typealias TTransactionStatus = TransactionStatus<BC.THasher.THash, BC.THasher.THash>
        public typealias TStorageChangeSet = StorageChangeSet<BC.THasher.THash>
        
        public typealias Params = SubstrateSigningParameters<BC.TExtrinsicEra, BC.THasher.THash,
                                                             BC.TAccountId, BC.TIndex,
                                                             BC.TExtrinsicPayment>
        public typealias Extensions = Tuple8<
            CheckNonZeroSenderExtension<BC, Params>,
            CheckSpecVersionExtension<BC, Params>,
            CheckTxVersionExtension<BC, Params>,
            CheckGenesisExtension<BC, Params>,
            CheckMortalityExtension<BC, Params>,
            CheckNonceExtension<BC, Params>,
            CheckWeightExtension<BC, Params>,
            ChargeTransactionPaymentExtension<BC, Params>
        >

        public typealias TExtrinsicManager = ExtrinsicV4Manager<StaticSignedExtensionsProvider<Extensions>>
        
        public init() {}

        @inlinable
        public func extrinsicManager() throws -> TExtrinsicManager {
            let provider = StaticSignedExtensionsProvider(extensions: Extensions(),
                                                          version: TExtrinsicManager.version)
            return TExtrinsicManager(extensions: provider)
        }
    }
}

public extension Configs.Registry where
    C == Configs.Substrate,
    Ext == Void
{
    @inlinable
    static var substrate: Self { Self(config: .init()) }
}
