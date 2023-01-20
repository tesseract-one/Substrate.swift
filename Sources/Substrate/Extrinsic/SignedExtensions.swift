//
//  SignedExtensions.swift
//
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct DynamicCheckSpecVersionExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckSpecVersion" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .u256(UInt256(substrate.runtimeVersion.specVersion))
    }
}

/// Ensure the transaction version registered in the transaction is the same as at present.
public struct DynamicCheckTxVersionExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckTxVersion" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .u256(UInt256(substrate.runtimeVersion.transactionVersion))
    }
}

/// Check genesis hash
public struct DynamicCheckGenesisExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckGenesis" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .bytes(substrate.genesisHash.data)
    }
}

public struct DynamicCheckNonZeroSenderExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckNonZeroSender" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct DynamicCheckNonceExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckNonce" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        if let nonce = params[.nonce] {
            return nonce
        }
        guard let from = params[.origin] else {
            throw ExtrinsicCodingError.valueNotFound(key: DynamicExtrinsicExtensionKey.origin.rawValue)
        }
        let account = try S.RT.TAccountId(value: from)
        let nonce = try await substrate.rpc.system.accountNextIndex(id: account)
        return .u256(UInt256(nonce))
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
}

public extension DynamicExtrinsicExtensionKey {
    static let nonce = Self("nonce")
    static let origin = Self("origin")
}

/// Check for transaction mortality.
public struct DynamicCheckMortalitySignedExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckMortality" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        if let era = params[.era] {
            // Normalize era
            let era = try ExtrinsicEra(value: era)
            let (first, second) = era.serialize()
            guard let second = second else {
                return try ExtrinsicEra.immortal.asValue()
            }
            return .variant(name: "Mortal\(first)", values: [.u256(UInt256(second))])
        }
        return try ExtrinsicEra.immortal.asValue()
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        if let hash = params[.blockHash] {
            return hash
        }
        guard let era = params[.era] else {
            return .bytes(substrate.genesisHash.data)
        }
        let pEra = try ExtrinsicEra(value: era) // Normalize era
        switch pEra {
        case .immortal:  return .bytes(substrate.genesisHash.data)
        case .mortal(period: _, phase: _):
            //let currentBlock = try await substrate.rpc.chain.getBlock().header.number
            //let birthBlock = pEra.birth(UInt64(currentBlock))
            //let hash = try await substrate.rpc.chain.getBlockHash(birthBlock)
            //return .bytes(hash.data)
            return .bytes(substrate.genesisHash.data)
        }
    }
}

public extension DynamicExtrinsicExtensionKey {
    static let era = Self("era")
    static let blockHash = Self("blockHash")
}

/// Resource limit check.
public struct DynamicCheckWeightExtension: DynamicExtrinsicExtension {
    public var identifier: String { "CheckWeight" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct DynamicChargeTransactionPaymentExtension: DynamicExtrinsicExtension {
    public var identifier: String { "ChargeTransactionPayment" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        guard let tip = params[.tip] else {
            throw ExtrinsicCodingError.valueNotFound(key: DynamicExtrinsicExtensionKey.tip.rawValue)
        }
        return tip
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
}

public extension DynamicExtrinsicExtensionKey {
    static let tip = Self("tip")
}

public struct DynamicPrevalidateAttestsExtension: DynamicExtrinsicExtension {
    public var identifier: String { "PrevalidateAttests" }
    
    public func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
    
    public func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void> {
        .sequence([])
    }
}
