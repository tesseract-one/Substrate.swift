//
//  StakingStorage.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

/// Rewards for the last `HISTORY_DEPTH` eras.
/// If reward hasn't been set or has been removed then 0 reward is returned.
public struct StakingErasRewardPointsStorageKey<S: Staking> {
    /// Era index
    public let index: EraIndex
}

extension StakingErasRewardPointsStorageKey: MapStorageKey {
    public typealias Value = S.TAccountId
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "ErasRewardPoints" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try index.encode(in: encoder, registry: registry)
    }
}

/// Number of eras to keep in history.
///
/// Information is kept for eras in `[current_era - history_depth; current_era]`.
///
/// Must be more than the number of eras delayed by session otherwise.
/// I.e. active era must always be in history.
/// I.e. `active_era > current_era - history_depth` must be guaranteed.
public struct StakingHistoryDepthStorageKey<S: Staking> {}

extension StakingHistoryDepthStorageKey: PlainStorageKey {
    public typealias Value = UInt32
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "HistoryDepth" }
}

/// Map from all locked "stash" accounts to the controller account.
public struct StakingBondedStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId
}

extension StakingBondedStorageKey: MapStorageKey {
    public typealias Value = Optional<S.TAccountId>
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "Bonded" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try stash.encode(in: encoder, registry: registry)
    }
}

/// Map from all (unlocked) "controller" accounts to the info regarding the staking.
public struct StakingLedgerStorageKey<S: Staking> {
    /// The controller account
    public let controller: S.TAccountId
}

extension StakingLedgerStorageKey: MapStorageKey {
    public typealias Value = StakingLedger<S.TAccountId, S.TBalance>
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "Ledger" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try controller.encode(in: encoder, registry: registry)
    }
}

/// Where the reward payment should be made. Keyed by stash.
public struct StakingPayeeStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId
}

extension StakingPayeeStorageKey: MapStorageKey {
    public typealias Value = RewardDestination<S.TAccountId>
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "Payee" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try stash.encode(in: encoder, registry: registry)
    }
}

/// The map from (wannabe) validator stash key to the preferences of that validator.
public struct StakingValidatorsStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId
}

extension StakingValidatorsStorageKey: MapStorageKey {
    public typealias Value = ValidatorPrefs
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "Validators" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try stash.encode(in: encoder, registry: registry)
    }
}

/// The map from nominator stash key to the set of stash keys of all validators to nominate.
public struct StakingNominatorsStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId
}

extension StakingNominatorsStorageKey: MapStorageKey {
    public typealias Value = Optional<Nominations<S.TAccountId>>
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "Nominators" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try stash.encode(in: encoder, registry: registry)
    }
}

/// The current era index.
///
/// This is the latest planned era, depending on how the Session pallet queues the validator
/// set, it might be active or not.
public struct StakingCurrentEraStorageKey<S: Staking> {}

extension StakingCurrentEraStorageKey: PlainStorageKey {
    public typealias Value = Optional<EraIndex>
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "CurrentEra" }
}

