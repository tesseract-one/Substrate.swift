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
    public typealias TAccountId = AccountId
    public typealias TAddress = Address<TAccountId, UInt32>
    public typealias THeader = Header<TBlockNumber, THash>
    //public typealias Extrinsic = OpaqueExtrinsic;
    public typealias TAccountData = AccountData<TBalance>
}

extension DefaultNodeRuntime: Stacking {}

extension DefaultNodeRuntime: Runtime {
    public typealias TSignature = MultiSignature
    public typealias TExtra = Data
    
    public var modules: [TypeRegistrator] {
        [PrimitivesModule<Self>(), SystemModule<Self>(), BalancesModule<Self>()]
    }
}
