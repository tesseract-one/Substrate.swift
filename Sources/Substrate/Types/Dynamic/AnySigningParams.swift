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
    
    public private(set) var partial: Partial
    
    public init(partial: Partial) throws {
        self.partial = partial
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
}

extension AnySigningParams: NonceSigningParameters {}

extension AnySigningParams.Partial: EraPartialSigningParameter {
    public typealias TEra = RT.TExtrinsicEra
    public typealias THash = RT.TBlock.THeader.THasher.THash
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
    public typealias TPayment = RT.TExtrinsicPayment
    public var tip: TPayment? {
        get { self["tip"] as? TPayment }
        set { self["tip"] = newValue }
    }
}

extension AnySigningParams: PaymentSigningParameters {}
