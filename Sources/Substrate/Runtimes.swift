//
//  Runtimes.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public struct DefaultNodeRuntime {}

extension DefaultNodeRuntime: Balances {
    public typealias TBalance = SUInt128
}

extension DefaultNodeRuntime: System {
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

extension DefaultNodeRuntime: Staking {}
extension DefaultNodeRuntime: Contracts {
    public typealias TGas = UInt64
}
extension DefaultNodeRuntime: Sudo {}

extension DefaultNodeRuntime: Session {
    public typealias TValidatorId = Self.TAccountId
    public typealias TKeys = BasicSessionKeys
}

extension DefaultNodeRuntime: Babe {}
extension DefaultNodeRuntime: Grandpa {}
extension DefaultNodeRuntime: ImOnline {}
extension DefaultNodeRuntime: Parachains {}
extension DefaultNodeRuntime: AuthorityDiscovery {}
extension DefaultNodeRuntime: BeefyApi {
    public typealias TBeefyValidatorSetId = UInt64
}

extension DefaultNodeRuntime: Runtime {
    public typealias TSignature = MultiSignature
    public typealias TExtrinsicExtra = DefaultExtrinsicExtra<Self>
    
    public var supportedSpecVersions: Range<UInt32> {
        return UInt32.min..<UInt32.max
    }
    
    public var modules: [ModuleBase] {
        [PrimitivesModule<Self>(), SystemModule<Self>(),
         StakingModule<Self>(), ContractsModule<Self>(),
         SudoModule<Self>(), SessionModule<Self>(),
         BabeModule<Self>(), GrandpaModule<Self>(),
         ImOnlineModule<Self>(), AuthorityDiscoveryModule<Self>(),
         BalancesModule<Self>(), StakingModule<Self>()]
    }
}
