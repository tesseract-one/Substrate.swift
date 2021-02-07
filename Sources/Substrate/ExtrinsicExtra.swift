//
//  ExtrinsicExtra.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation
import ScaleCodec

public protocol SignedExtrinsicExtra: SignedExtension {
    associatedtype S: System
    associatedtype ExtrinsicExtra: SignedExtension
    
    var extra: ExtrinsicExtra { get }
    
    init(specVersion: UInt32, txVersion: UInt32, nonce: S.TIndex, genesisHash: S.THash)
}

/// Default `SignedExtrinsicExtra` for substrate runtimes.
public struct DefaultExtrinsicExtra<S: System & Balances> {
    public let specVersion: UInt32
    public let txVersion: UInt32
    public let nonce: S.TIndex
    public let genesisHash: S.THash
    
    public init(specVersion: UInt32, txVersion: UInt32, nonce: S.TIndex, genesisHash: S.THash) {
        self.specVersion = specVersion
        self.txVersion = txVersion
        self.nonce = nonce
        self.genesisHash = genesisHash
    }
}

extension DefaultExtrinsicExtra: SignedExtension {
    public typealias AdditionalSignedPayload = Self.ExtrinsicExtra.AdditionalSignedPayload
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let tuple = try ExtrinsicExtra(from: decoder, registry: registry)
        specVersion = tuple._0.version
        txVersion = tuple._1.version
        genesisHash = tuple._2.genesisHash
        nonce = tuple._4.nonce
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try self.extra.encode(in: encoder, registry: registry)
    }
    
    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try self.extra.additionalSignedPayload()
    }
    
    public var identifier: [String] {
        return self.extra.identifier
    }
    
    public static var IDENTIFIER: String { "DefaultExtra" }
}

extension DefaultExtrinsicExtra: SignedExtrinsicExtra {
    public typealias ExtrinsicExtra = STuple7<
        CheckSpecVersionSignedExtension<S>,
        CheckTxVersionSignedExtension<S>,
        CheckGenesisSignedExtension<S>,
        CheckEraSignedExtension<S>,
        CheckNonceSignedExtension<S>,
        CheckWeightSignedExtension<S>,
        ChargeTransactionPaymentSignedExtension<S>
    >
    
    public var extra: ExtrinsicExtra {
        return STuple7(
            CheckSpecVersionSignedExtension(version: specVersion),
            CheckTxVersionSignedExtension(version: txVersion),
            CheckGenesisSignedExtension(genesisHash: genesisHash),
            CheckEraSignedExtension(era: .immortal, genesisHash: genesisHash),
            CheckNonceSignedExtension(nonce: nonce),
            CheckWeightSignedExtension(),
            ChargeTransactionPaymentSignedExtension(payment: S.TBalance(uintValue: S.TBalance.compactMax))
        )
    }
}

