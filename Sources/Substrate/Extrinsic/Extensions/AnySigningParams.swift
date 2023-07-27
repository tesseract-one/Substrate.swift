//
//  AnySigningParams.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation

public struct AnySigningParams<RT: Config>: ExtraSigningParameters {
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
    
    private var params: Partial
    
    public init(partial: Partial) throws {
        self.params = partial
    }
    
    public subscript(key: String) -> Any? {
        get { params[key] }
        set { params[key] = newValue }
    }
}

extension AnySigningParams.Partial: NoncePartialSigningParameter {
    public typealias TNonce = RT.TIndex
    public typealias TAccountId = RT.TAccountId
    public var account: TAccountId? {
        get { self["account"] as? TAccountId }
        set { self["account"] = newValue }
    }
    public var nonce: TNonce? {
        get { self["nonce"] as? TNonce }
        set { self["nonce"] = newValue }
    }
    public func nonce(_ nonce: TNonce) -> Self {
        var new = self
        new.nonce = nonce
        return new
    }
    public static func nonce(_ nonce: TNonce) -> Self {
        var new = Self()
        new.nonce = nonce
        return new
    }
}

extension AnySigningParams: NonceSigningParameters {
    public var nonce: TPartial.TNonce { params.nonce! }
}

extension AnySigningParams.Partial: EraPartialSigningParameter {
    public typealias TEra = RT.TExtrinsicEra
    public typealias THash = RT.TBlock.THeader.THasher.THash
    public var era: TEra? {
        get { params["era"] as? TEra }
        set { params["era"] = newValue }
    }
    public func era(_ era: TEra) -> Self {
        var new = self
        new.era = era
        return new
    }
    public static func era(_ era: TEra) -> Self {
        var new = Self()
        new.era = era
        return new
    }
    public var blockHash: THash? {
        get { params["blockHash"] as? THash }
        set { params["blockHash"] = newValue }
    }
    public func blockHash(_ hash: THash) -> Self {
        var new = self
        new.blockHash = hash
        return new
    }
    public static func blockHash(_ hash: THash) -> Self {
        var new = Self()
        new.blockHash = hash
        return new
    }
}

extension AnySigningParams: EraSigningParameters {
    public var era: RT.TExtrinsicEra { params.era! }
    public var blockHash: RT.TBlock.THeader.THasher.THash { params.blockHash! }
}

extension AnySigningParams.Partial: PaymentPartialSigningParameter {
    public typealias TPayment = RT.TExtrinsicPayment
    public var tip: TPayment? {
        get { self["tip"] as? TPayment }
        set { self["tip"] = newValue }
    }
    public func tip(_ tip: TPayment) -> Self {
        var new = self
        new.tip = tip
        return new
    }
    public static func tip(_ tip: TPayment) -> Self {
        var new = Self()
        new.tip = tip
        return new
    }
}

extension AnySigningParams: PaymentSigningParameters {
    public var tip: RT.TExtrinsicPayment { params.tip! }
}
