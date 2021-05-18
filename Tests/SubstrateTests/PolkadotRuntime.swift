//
//  PolkadotRuntime.swift
//  
//
//  Created by Yehor Popovych on 15.05.2021.
//

import Foundation
import Substrate

struct PolkadotRuntime {}

extension PolkadotRuntime: Balances {
    public typealias TBalance = SUInt128
}

extension PolkadotRuntime: System {
    public typealias TIndex = UInt32
    public typealias TBlockNumber = UInt32
    public typealias THash = Hash256
    public typealias THasher = HBlake2b256
    public typealias TAccountId = Sr25519PublicKey
    public typealias TAddress = MultiAddress<TAccountId, TIndex>
    public typealias THeader = Header<TBlockNumber, THash>
    public typealias TExtrinsic = OpaqueExtrinsic
    public typealias TAccountData = AccountData<TBalance>
}

extension PolkadotRuntime: Staking {}

extension PolkadotRuntime: Session {
    public typealias TValidatorId = Self.TAccountId
    public typealias TKeys = KusamaSessionKeys
}

extension PolkadotRuntime: Runtime {
    public typealias TSignature = MultiSignature
    public typealias TExtrinsicExtra = DefaultExtrinsicExtra<Self>
    
    public var modules: [TypeRegistrator] {
        [PrimitivesModule<Self>(), SystemModule<Self>(),
         SessionModule<Self>(), BalancesModule<Self>(),
         StakingModule<Self>()]
    }
}

