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
    public let index: EraIndex?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(index: EraIndex?) {
        self.index = index
        self._hash = nil
    }
}

extension StakingErasRewardPointsStorageKey: MapStorageKey {
    public typealias Value = S.TAccountId
    public typealias Module = StakingModule<S>
    public typealias K = EraIndex
    
    public static var FIELD: String { "ErasRewardPoints" }
    
    public var key: K? { index }
    public var hash: Data? { _hash }
    
    public init(key: K?, hash: Data) {
        self.index = key
        self._hash = hash
    }
}

/// Number of eras to keep in history.
///
/// Information is kept for eras in `[current_era - history_depth; current_era]`.
///
/// Must be more than the number of eras delayed by session otherwise.
/// I.e. active era must always be in history.
/// I.e. `active_era > current_era - history_depth` must be guaranteed.
public struct StakingHistoryDepthStorageKey<S: Staking> {
    public init() {}
}

extension StakingHistoryDepthStorageKey: PlainStorageKey {
    public typealias Value = UInt32
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "HistoryDepth" }
}

/// Map from all locked "stash" accounts to the controller account.
public struct StakingBondedStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(stash: S.TAccountId?) {
        self.stash = stash
        self._hash = nil
    }
}

extension StakingBondedStorageKey: MapStorageKey {
    public typealias Value = Optional<S.TAccountId>
    public typealias Module = StakingModule<S>
    public typealias K = S.TAccountId
    
    public static var FIELD: String { "Bonded" }
    
    public var key: K? { stash }
    public var hash: Data? { _hash }
    
    public init(key: K?, hash: Data) {
        self.stash = key
        self._hash = hash
    }
}

/// Map from all (unlocked) "controller" accounts to the info regarding the staking.
public struct StakingLedgerStorageKey<S: Staking> {
    /// The controller account
    public let controller: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(controller: S.TAccountId?) {
        self.controller = controller
        self._hash = nil
    }
}

extension StakingLedgerStorageKey: MapStorageKey {
    public typealias Value = StakingLedger<S.TAccountId, S.TBalance>
    public typealias Module = StakingModule<S>
    public typealias K = S.TAccountId
    
    public static var FIELD: String { "Ledger" }
    
    public var key: K? { controller }
    public var hash: Data? { _hash }
    
    public init(key: K?, hash: Data) {
        self.controller = key
        self._hash = hash
    }
}

/// Where the reward payment should be made. Keyed by stash.
public struct StakingPayeeStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(stash: S.TAccountId?) {
        self.stash = stash
        self._hash = nil
    }
}

extension StakingPayeeStorageKey: MapStorageKey {
    public typealias Value = RewardDestination<S.TAccountId>
    public typealias Module = StakingModule<S>
    public typealias K = S.TAccountId
    
    public static var FIELD: String { "Payee" }
    
    public var key: K? { stash }
    public var hash: Data? { _hash }
    
    public init(key: K?, hash: Data) {
        self.stash = key
        self._hash = hash
    }
}

/// The map from (wannabe) validator stash key to the preferences of that validator.
public struct StakingValidatorsStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(stash: S.TAccountId?) {
        self.stash = stash
        self._hash = nil
    }
}

extension StakingValidatorsStorageKey: MapStorageKey {
    public typealias Value = ValidatorPrefs
    public typealias Module = StakingModule<S>
    public typealias K = S.TAccountId
    
    public static var FIELD: String { "Validators" }
    
    public var key: K? { stash }
    public var hash: Data? { _hash }
    
    public init(key: K?, hash: Data) {
        self.stash = key
        self._hash = hash
    }
}

/// The map from nominator stash key to the set of stash keys of all validators to nominate.
public struct StakingNominatorsStorageKey<S: Staking> {
    /// Tٗhe stash account
    public let stash: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(stash: S.TAccountId?) {
        self.stash = stash
        self._hash = nil
    }
}

extension StakingNominatorsStorageKey: MapStorageKey {
    public typealias Value = Optional<Nominations<S.TAccountId>>
    public typealias Module = StakingModule<S>
    public typealias K = S.TAccountId
    
    public static var FIELD: String { "Nominators" }
    
    public var key: K? { stash }
    public var hash: Data? { _hash }
    
    public init(key: K?, hash: Data) {
        self.stash = key
        self._hash = hash
    }
}

/// The current era index.
///
/// This is the latest planned era, depending on how the Session pallet queues the validator
/// set, it might be active or not.
public struct StakingCurrentEraStorageKey<S: Staking> {
    public init() {}
}

extension StakingCurrentEraStorageKey: PlainStorageKey {
    public typealias Value = Optional<EraIndex>
    public typealias Module = StakingModule<S>
    
    public static var FIELD: String { "CurrentEra" }
}

