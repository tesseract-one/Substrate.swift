//
//  AnySigningParams.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation

public struct AnySigningParams<BC: BasicConfig>: ExtraSigningParameters {
    public struct Partial: Default {
        private var params: [String: Any]
        
        public init() {
            self.params = [:]
        }
        
        public static var `default`: Self { Self() }
        
        public subscript(key: String) -> Any? {
            get { params[key] }
            set { params[key] = newValue }
        }
    }
    
    public typealias TPartial = Partial
    
    public private(set) var partial: Partial
    
    public init(partial: Partial) throws {
        self.partial = partial
    }
}

extension AnySigningParams.Partial: NoncePartialSigningParameter {
    public typealias TNonce = SBT<BC>.Index
    public typealias TAccountId = SBT<BC>.AccountId
    public var account: TAccountId? {
        get { self["account"] as? TAccountId }
        set { self["account"] = newValue }
    }
    public var nonce: TNonce? {
        get { self["nonce"] as? TNonce }
        set { self["nonce"] = newValue }
    }
}

extension AnySigningParams: NonceSigningParameters {}

extension AnySigningParams.Partial: EraPartialSigningParameter {
    public typealias TEra = SBT<BC>.ExtrinsicEra
    public typealias THash = SBT<BC>.Hash
    public var era: TEra? {
        get { params["era"] as? TEra }
        set { params["era"] = newValue }
    }
    public var blockHash: THash? {
        get { params["blockHash"] as? THash }
        set { params["blockHash"] = newValue }
    }
}

extension AnySigningParams: EraSigningParameters {}

extension AnySigningParams.Partial: PaymentPartialSigningParameter {
    public typealias TPayment = SBT<BC>.ExtrinsicPayment
    public var tip: TPayment? {
        get { self["tip"] as? TPayment }
        set { self["tip"] = newValue }
    }
}

extension AnySigningParams: PaymentSigningParameters {}
