//
//  StackingTypes.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public typealias EraIndex = UInt32
public typealias Perbill = UInt32
public typealias RewardPoint = UInt32

/// A destination account for payment.
public enum RewardDestination<AccountId: ScaleDynamicCodable>: ScaleDynamicCodable {
    /// Pay into the stash account, increasing the amount at stake accordingly.
    case staked
    /// Pay into the stash account, not increasing the amount at stake.
    case stash
    /// Pay into the controller account.
    case controller
    /// Pay into a specified account.
    case account(AccountId)
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = .staked
        case 1: self = .stash
        case 2: self = .controller
        case 3: self = try .account(AccountId(from: decoder, registry: registry))
        default: throw decoder.enumCaseError(for: id)
        }
    }
       
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        switch self {
        case .staked: try encoder.encode(0, .enumCaseId)
        case .stash: try encoder.encode(1, .enumCaseId)
        case .controller: try encoder.encode(2, .enumCaseId)
        case .account(let a): try a.encode(in: encoder.encode(3, .enumCaseId), registry: registry)
        }
    }
}

/// Just a Balance/BlockNumber tuple to encode when a chunk of funds will be unlocked.
public struct UnlockChunk<Balance: CompactCodable>: ScaleCodable, ScaleDynamicCodable {
    /// Amount of funds to be unlocked.
    public let value: Balance
    /// Era number at which point it'll be unlocked.
    public let era: EraIndex
    
    public init(from decoder: ScaleDecoder) throws {
        value = try decoder.decode(.compact)
        era = try decoder.decode(.compact)
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(value, .compact).encode(era, .compact)
    }
}

/// The ledger of a (bonded) stash.
public struct StakingLedger<AccountId: ScaleDynamicCodable, Balance: CompactCodable>: ScaleDynamicCodable {
    /// The stash account whose balance is actually locked and at stake.
    public let stash: AccountId
    /// The total amount of the stash's balance that we are currently accounting for. It's just active plus all the unlocking balances.
    public let total: Balance
    /// The total amount of the stash's balance that will be at stake in any forthcoming rounds.
    public let active: Balance
    /// Any balance that is becoming free, which may eventually be transferred out of the stash (assuming it doesn't get slashed first).
    public let unlocking: Array<UnlockChunk<Balance>>
    /// List of eras for which the stakers behind a validator have claimed rewards. Only updated for validators.
    public let claimedRewards: Array<EraIndex>
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        stash = try AccountId(from: decoder, registry: registry)
        total = try decoder.decode(.compact)
        active = try decoder.decode(.compact)
        unlocking = try decoder.decode()
        claimedRewards = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try stash.encode(in: encoder, registry: registry)
        try encoder
            .encode(total, .compact).encode(active, .compact)
            .encode(unlocking).encode(claimedRewards)
    }
}

/// Preference of what happens regarding validation.
public struct ValidatorPrefs: ScaleCodable, ScaleDynamicCodable {
    /// Reward that validator takes up-front; only the rest is split between themselves and nominators.
    public let commission: Perbill
    
    public init(from decoder: ScaleDecoder) throws {
        commission = try decoder.decode(.compact)
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(commission, .compact)
    }
}

/// A record of the nominations made by a specific account.
public struct Nominations<AccountId: ScaleDynamicCodable>: ScaleDynamicCodable {
    /// The targets of nomination.
    public let targets: Array<AccountId>
    /// The era the nominations were submitted.
    ///
    /// Except for initial nominations which are considered submitted at era 0.
    public let submittedIn: EraIndex
    /// Whether the nominations have been suppressed. This can happen due to slashing of the
    /// validators, or other events that might invalidate the nomination.
    ///
    /// NOTE: this for future proofing and is thus far not used.
    public let suppressed: Bool
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        targets = try Array<AccountId>(from: decoder, registry: registry)
        submittedIn = try decoder.decode()
        suppressed = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try targets.encode(in: encoder, registry: registry)
        try encoder.encode(submittedIn).encode(suppressed)
    }
}

/// Reward points of an era. Used to split era total payout between validators.
///
/// This points will be used to reward validators and their respective nominators.
public struct EraRewardPoints<AccountId: ScaleDynamicCodable & Hashable>: ScaleDynamicCodable {
    /// Total number of points. Equals the sum of reward points for each validator.
    public let total: RewardPoint
    /// The reward points earned by a given validator.
    public let individual: Dictionary<AccountId, RewardPoint>
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        total = try decoder.decode()
        individual = try Dictionary<AccountId, RewardPoint>(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encoder.encode(total)
        try individual.encode(in: encoder, registry: registry)
    }
}
