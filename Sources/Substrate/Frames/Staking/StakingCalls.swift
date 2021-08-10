//
//  StakingCalls.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

/// Preference of what happens regarding validation.
public struct StakingSetPayeeCall<S: Staking> {
    /// The payee
    public let payee: RewardDestination<S.TAccountId>
}

extension StakingSetPayeeCall: Call {
    public typealias Module = StakingModule<S>
    
    public static var FUNCTION: String { "set_payee" }
    
    public var params: Dictionary<String, Any> { ["payee": payee] }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        payee = try RewardDestination<S.TAccountId>(from: decoder, registry: registry)
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try payee.encode(in: encoder, registry: registry)
    }
}

/// Declare no desire to either validate or nominate.
///
/// Effective at the beginning of the next era.
///
/// The dispatch origin for this call must be _Signed_ by the controller, not the stash.
/// Can only be called when [`EraElectionStatus`] is `Closed`.
public struct StakingChillCall<S: Staking> {}

extension StakingChillCall: Call {
    public typealias Module = StakingModule<S>
    
    public static var FUNCTION: String { "chill" }
    
    public var params: Dictionary<String, Any> { [:] }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
    }
}

/// Declare the desire to validate for the origin controller.
///
/// Effective at the beginning of the next era.
///
/// The dispatch origin for this call must be _Signed_ by the controller, not the stash.
/// Can only be called when [`EraElectionStatus`] is `Closed`.
public struct StakingValidateCall<S: Staking> {
    /// Validation preferences
    public let prefs: ValidatorPrefs
}

extension StakingValidateCall: Call {
    public typealias Module = StakingModule<S>
    
    public static var FUNCTION: String { "validate" }
    
    public var params: Dictionary<String, Any> { ["prefs": prefs] }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        prefs = try decoder.decode()
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try prefs.encode(in: encoder, registry: registry)
    }
}

/// Declare the desire to nominate `targets` for the origin controller.
///
/// Effective at the beginning of the next era.
///
/// The dispatch origin for this call must be _Signed_ by the controller, not the stash.
/// Can only be called when [`EraElectionStatus`] is `Closed`.
public struct StakingNominateCall<S: Staking> {
    /// The targets that are being nominated
    public let targets: Array<S.TAddress>
}

extension StakingNominateCall: Call {
    public typealias Module = StakingModule<S>
    
    public static var FUNCTION: String { "nominate" }
    
    public var params: Dictionary<String, Any> { ["targets": targets] }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        targets = try Array<S.TAddress>(from: decoder, registry: registry)
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try targets.encode(in: encoder, registry: registry)
    }
}
