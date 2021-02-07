//
//  SignedExtensions.swift
//  
//
//  Created by Yehor Popovych on 2/6/21.
//

import Foundation
import ScaleCodec
import SubstratePrimitives


/// Ensure the runtime version registered in the transaction is the same as at present.
public struct CheckSpecVersionSignedExtension<S: System>: ScaleCodable, ScaleDynamicCodable {
    public let version: UInt32!
    
    public init(version: UInt32) {
        self.version = version
    }
    
    public init(from decoder: ScaleDecoder) throws { self.version = nil }
    public func encode(in encoder: ScaleEncoder) throws {}
}

extension CheckSpecVersionSignedExtension: SignedExtension {
//    public typealias AccountId = S.TAccountId
    public typealias AdditionalSignedPayload = UInt32
    
    public static var IDENTIFIER: String { "CheckSpecVersion" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { version }
}

/// Ensure the transaction version registered in the transaction is the same as at present.
public struct CheckTxVersionSignedExtension<S: System>: ScaleCodable, ScaleDynamicCodable {
    public let version: UInt32!
    
    public init(version: UInt32) {
        self.version = version
    }
    
    public init(from decoder: ScaleDecoder) throws { self.version = nil }
    public func encode(in encoder: ScaleEncoder) throws {}
}

extension CheckTxVersionSignedExtension: SignedExtension {
//    public typealias AccountId = S.TAccountId
    public typealias AdditionalSignedPayload = UInt32
    
    public static var IDENTIFIER: String { "CheckTxVersion" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { version }
}

/// Check genesis hash
public struct CheckGenesisSignedExtension<S: System>: ScaleCodable, ScaleDynamicCodable {
    public let genesisHash: S.THash!
    
    public init(genesisHash: S.THash) {
        self.genesisHash = genesisHash
    }
    
    public init(from decoder: ScaleDecoder) throws { self.genesisHash = nil }
    public func encode(in encoder: ScaleEncoder) throws {}
}

extension CheckGenesisSignedExtension: SignedExtension {
//    public typealias AccountId = S.TAccountId
    public typealias AdditionalSignedPayload = S.THash
    
    public static var IDENTIFIER: String { "CheckGenesis" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { genesisHash }
}

/// Check for transaction mortality.
public struct CheckEraSignedExtension<S: System>: ScaleCodable, ScaleDynamicCodable {
    public let era: ExtrinsicEra
    public let genesisHash: S.THash!
    
    public init(era: ExtrinsicEra, genesisHash: S.THash) {
        self.era = era
        self.genesisHash = genesisHash
    }
    
    public init(from decoder: ScaleDecoder) throws {
        self.era = try decoder.decode()
        self.genesisHash = nil
    }
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(era)
    }
}

extension CheckEraSignedExtension: SignedExtension {
//    public typealias AccountId = S.TAccountId
    public typealias AdditionalSignedPayload = S.THash
    
    public static var IDENTIFIER: String { "CheckEra" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { genesisHash }
}

/// Nonce check and increment to give replay protection for transactions.
public struct CheckNonceSignedExtension<S: System>: ScaleCodable, ScaleDynamicCodable {
    public let nonce: S.TIndex
    
    public init(nonce: S.TIndex) {
        self.nonce = nonce
    }
    
    public init(from decoder: ScaleDecoder) throws {
        self.nonce = try decoder.decode(.compact)
    }
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(nonce, .compact)
    }
}

extension CheckNonceSignedExtension: SignedExtension {
//    public typealias AccountId = S.TAccountId
    public typealias AdditionalSignedPayload = DNull
    
    public static var IDENTIFIER: String { "CheckNonce" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { DNull() }
}

/// Resource limit check.
public struct CheckWeightSignedExtension<S: System>: ScaleCodable, ScaleDynamicCodable {
    public init() {}
    
    public init(from decoder: ScaleDecoder) throws {}
    public func encode(in encoder: ScaleEncoder) throws {}
}

extension CheckWeightSignedExtension: SignedExtension {
//    public typealias AccountId = S.TAccountId
    public typealias AdditionalSignedPayload = DNull
    
    public static var IDENTIFIER: String { "CheckWeight" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { DNull() }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct ChargeTransactionPaymentSignedExtension<B: Balances>: ScaleCodable, ScaleDynamicCodable {
    public let payment: B.TBalance
    
    public init(payment: B.TBalance) {
        self.payment = payment
    }
    
    public init(from decoder: ScaleDecoder) throws {
        payment = try decoder.decode(.compact)
    }
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(payment, .compact)
    }
}

extension ChargeTransactionPaymentSignedExtension: SignedExtension {
//    public typealias AccountId = B.TAccountId
    public typealias AdditionalSignedPayload = DNull
    
    public static var IDENTIFIER: String { "ChargeTransactionPayment" }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload { DNull() }
}
