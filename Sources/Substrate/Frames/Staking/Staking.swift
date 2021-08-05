//
//  Staking.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public protocol Staking: Balances {}

open class StakingModule<S: Staking>: ModuleProtocol {
    public typealias Frame = S
    
    public static var NAME: String { "Staking" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        try registry.register(type: RewardDestination<S.TAccountId>.self, as: .type(name: "RewardDestination"))
        try registry.register(type: EraIndex.self, as: .type(name: "EraIndex"))
        try registry.register(type: SCompact<EraIndex>.self, as: .compact(type: .type(name: "EraIndex")))
        try registry.register(type: RewardPoint.self, as: .type(name: "RewardPoint"))
        try registry.register(type: SCompact<RewardPoint>.self, as: .compact(type: .type(name: "RewardPoint")))
        try registry.register(type: Perbill.self, as: .type(name: "Perbill"))
        try registry.register(type: SCompact<Perbill>.self, as: .compact(type: .type(name: "Perbill")))
        try registry.register(type: UnlockChunk<S.TBalance>.self, as: .type(name: "UnlockChunk"))
        try registry.register(type: StakingLedger<S.TAccountId, S.TBalance>.self, as: .type(name: "StakingLedger"))
        try registry.register(type: ValidatorPrefs.self, as: .type(name: "ValidatorPrefs"))
        try registry.register(type: Nominations<S.TAccountId>.self, as: .type(name: "Nominations"))
        try registry.register(type: EraRewardPoints<S.TAccountId>.self, as: .type(name: "EraRewardPoints"))
        try registry.register(call: StakingSetPayeeCall<S>.self)
        try registry.register(call: StakingChillCall<S>.self)
        try registry.register(call: StakingValidateCall<S>.self)
        try registry.register(call: StakingNominateCall<S>.self)
    }
}
