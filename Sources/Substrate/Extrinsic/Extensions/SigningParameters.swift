//
//  SigningParameters.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import ScaleCodec

public protocol AnyAccountPartialSigningParameter {
    mutating func setAccount<A: AccountId>(_ account: A?) throws
}

public protocol NoncePartialSigningParameter<TNonce, TAccountId>: AnyAccountPartialSigningParameter {
    associatedtype TNonce: UnsignedInteger
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
}

public protocol EraPartialSigningParameter<TEra, THash> {
    associatedtype TEra: SomeExtrinsicEra
    associatedtype THash: Hash
    
    var era: TEra? { get set }
    func era(_ era: TEra) -> Self
    static func era(_ era: TEra) -> Self
    
    var blockHash: THash? { get set }
    func blockHash(_ hash: THash) -> Self
    static func blockHash(_ hash: THash) -> Self
}

public protocol EraSigningParameters: ExtraSigningParameters
    where TPartial: EraPartialSigningParameter
{
    var era: TPartial.TEra { get }
    var blockHash: TPartial.THash { get }
}

public protocol PaymentPartialSigningParameter<TPayment> {
    associatedtype TPayment: ValueRepresentable & Default
    
    var tip: TPayment? { get set }
    func tip(_ tip: TPayment) -> Self
    static func tip(_ tip: TPayment) -> Self
}

public protocol PaymentSigningParameters: ExtraSigningParameters
    where TPartial: PaymentPartialSigningParameter
{
    var tip: TPartial.TPayment { get }
}
