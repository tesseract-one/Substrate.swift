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
    public typealias TAccountId = AccountId<Sr25519PublicKey>
    public typealias TAddress = Address<TAccountId, UInt32>
    public typealias THeader = Header<TBlockNumber, THash>
    public typealias TExtrinsic = OpaqueExtrinsic
    public typealias TAccountData = AccountData<TBalance>
}

extension DefaultNodeRuntime: Staking {}
extension DefaultNodeRuntime: Contracts {}
extension DefaultNodeRuntime: Sudo {}

extension DefaultNodeRuntime: Session {
    public typealias TValidatorId = Self.TAccountId
    public typealias TKeys = BasicSessionKeys
}

extension DefaultNodeRuntime: Runtime {
    public typealias TSignature = MultiSignature
    public typealias TExtrinsicExtra = DefaultExtrinsicExtra<Self>
    
    public var modules: [TypeRegistrator] {
        [PrimitivesModule<Self>(), SystemModule<Self>(),
         StakingModule<Self>(), ContractsModule<Self>(),
         SudoModule<Self>(), SessionModule<Self>(),
         BalancesModule<Self>(), StakingModule<Self>()]
    }
}
