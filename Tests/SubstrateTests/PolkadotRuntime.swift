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
    public typealias TWeight = UInt64
    public typealias THash = Hash256
    public typealias THasher = HBlake2b256
    public typealias TAccountId = Sr25519PublicKey
    public typealias TAddress = MultiAddress<TAccountId, TIndex>
    public typealias THeader = Header<TBlockNumber, THash>
    public typealias TExtrinsic = Extrinsic<TAddress, MultiSignature, DefaultExtrinsicExtra<Self>>
    public typealias TAccountData = AccountData<TBalance>
}

extension PolkadotRuntime: Staking {}

extension PolkadotRuntime: Session {
    public typealias TValidatorId = Self.TAccountId
    public typealias TKeys = KusamaSessionKeys
}

extension PolkadotRuntime: Babe {}
extension PolkadotRuntime: Grandpa {}
extension PolkadotRuntime: ImOnline {}
extension PolkadotRuntime: Parachains {}
extension PolkadotRuntime: AuthorityDiscovery {}
extension PolkadotRuntime: BeefyApi {
    public typealias TBeefyPayload = Hash256
    public typealias TBeefyValidatorSetId = UInt64
    public typealias TBeefySignature = EcdsaSignature
}

extension PolkadotRuntime: Runtime {
    public var supportedSpecVersions: Range<UInt32> {
        return 30..<UInt32.max
    }
    
    public var modules: [ModuleBase] {
        [PrimitivesModule<Self>(), SystemModule<Self>(),
         SessionModule<Self>(), BabeModule<Self>(),
         GrandpaModule<Self>(), ImOnlineModule<Self>(),
         AuthorityDiscoveryModule<Self>(),
         BalancesModule<Self>(), StakingModule<Self>()]
    }
}

