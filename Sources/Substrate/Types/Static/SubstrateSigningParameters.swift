//
//  SubstrateSigningParameters.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

public struct SubstrateSigningParameters<
    E: SomeExtrinsicEra, H: Hash, A: AccountId,
    N: UnsignedInteger & ValueRepresentable & ValidatableRuntimeType,
    P: ValueRepresentable & ValidatableRuntimeType
>: EraSigningParameters, NonceSigningParameters, PaymentSigningParameters {
    public typealias TPartial = Partial
    
    public let partial: TPartial
    
    public init(partial: Partial) throws {
        self.partial = partial
    }
}

public extension SubstrateSigningParameters {
    struct Partial: EraPartialSigningParameter, NoncePartialSigningParameter, PaymentPartialSigningParameter {
        public typealias TEra = E
        public typealias THash = H
        public typealias TNonce = N
        public typealias TAccountId = A
        public typealias TPayment = P
        
        public var era: TEra?
        public var blockHash: THash?
        public var account: TAccountId?
        public var nonce: TNonce?
        public var tip: TPayment?
        
        public static var `default`: Self { Self() }
    }
}
