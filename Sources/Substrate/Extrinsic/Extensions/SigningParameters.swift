//
//  SigningParameters.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import ScaleCodec

public protocol AnyAccountPartialSigningParameter: Default {
    mutating func setAccount<A: AccountId>(_ account: A?) throws
}

public protocol NoncePartialSigningParameter<TNonce, TAccountId>: AnyAccountPartialSigningParameter {
    associatedtype TNonce: UnsignedInteger & ValueRepresentable & RuntimeDynamicValidatable
    associatedtype TAccountId: AccountId
    
    var account: TAccountId? { get set }
    var nonce: TNonce? { get set }
    
    func nonce(_ nonce: TNonce) -> Self
    static func nonce(_ nonce: TNonce) -> Self
}

public protocol NonceSigningParameters: ExtraSigningParameters
    where TPartial: NoncePartialSigningParameter
{
    var nonce: TPartial.TNonce { get }
}

public extension NoncePartialSigningParameter {
    mutating func setAccount<A: AccountId>(_ account: A?) throws {
        guard A.self == TAccountId.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TAccountId.self, got: A.self)
        }
        self.account = account as! TAccountId?
    }
    
    func nonce(_ nonce: TNonce) -> Self {
        var copy = self
        copy.nonce = nonce
        return copy
    }
    
    static func nonce(_ nonce: TNonce) -> Self {
        var val = Self.default
        val.nonce = nonce
        return val
    }
}

public extension NonceSigningParameters {
    var nonce: TPartial.TNonce { partial.nonce! }
}

public protocol EraPartialSigningParameter<TEra, THash>: Default {
    associatedtype TEra: SomeExtrinsicEra
    associatedtype THash: Hash
    
    var era: TEra? { get set }
    func era(_ era: TEra) -> Self
    static func era(_ era: TEra) -> Self
    
    var blockHash: THash? { get set }
    func blockHash(_ hash: THash) -> Self
    static func blockHash(_ hash: THash) -> Self
}

public extension EraPartialSigningParameter {
    func era(_ era: TEra) -> Self {
        var copy = self
        copy.era = era
        return copy
    }
    
    static func era(_ era: TEra) -> Self {
        var val = Self.default
        val.era = era
        return val
    }
    
    func blockHash(_ hash: THash) -> Self {
        var copy = self
        copy.blockHash = hash
        return copy
    }
    
    static func blockHash(_ hash: THash) -> Self {
        var val = Self.default
        val.blockHash = hash
        return val
    }
}

public protocol EraSigningParameters: ExtraSigningParameters
    where TPartial: EraPartialSigningParameter
{
    var era: TPartial.TEra { get }
    var blockHash: TPartial.THash { get }
}

public extension EraSigningParameters {
    var era: TPartial.TEra { partial.era! }
    var blockHash: TPartial.THash { partial.blockHash! }
}

public protocol PaymentPartialSigningParameter<TPayment>: Default {
    associatedtype TPayment: ValueRepresentable & RuntimeDynamicValidatable
    
    var tip: TPayment? { get set }
    func tip(_ tip: TPayment) -> Self
    static func tip(_ tip: TPayment) -> Self
}

public extension PaymentPartialSigningParameter {
    func tip(_ tip: TPayment) -> Self {
        var copy = self
        copy.tip = tip
        return copy
    }
    
    static func tip(_ tip: TPayment) -> Self {
        var val = Self.default
        val.tip = tip
        return val
    }
}

public protocol PaymentSigningParameters: ExtraSigningParameters
    where TPartial: PaymentPartialSigningParameter
{
    var tip: TPartial.TPayment { get }
}

public extension PaymentSigningParameters {
    var tip: TPartial.TPayment { partial.tip! }
}
