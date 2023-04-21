//
//  DynamicSignedExtensions.swift
//
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct DynamicCheckSpecVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .primitive(.u256(UInt256(substrate.runtime.version.specVersion))),
              context: id)
    }
}

/// Ensure the transaction version registered in the transaction is the same as at present.
public struct DynamicCheckTxVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .primitive(.u256(UInt256(substrate.runtime.version.transactionVersion))),
              context: id)
    }
}

/// Check genesis hash
public struct DynamicCheckGenesisExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkGenesis }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .primitive(.bytes(substrate.runtime.genesisHash.data)), context: id)
    }
}

public struct DynamicCheckNonZeroSenderExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct DynamicCheckNonceExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonce }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        guard let nonce = params.nonce else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "nonce")
        }
        return Value(value: .primitive(.u256(UInt256(nonce))), context: id)
//        switch params.nonce {
//        case .nonce(let nonce): return Value(value: .primitive(.u256(UInt256(nonce))), context: id)
//        case .id(let accId):
//            let nonce = try await substrate.rpc.system.accountNextIndex(id: accId)
//            return Value(value: .primitive(.u256(UInt256(nonce))), context: id)
//        }
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
}

/// Check for transaction mortality.
public struct DynamicCheckMortalitySignedExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        let era = params.era ?? S.RC.TExtrinsicEra.immortal
        return try era.asValue().mapContext { id }
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        if let hash = params.blockHash {
            return try hash.asValue().mapContext { id }
        }
        let era = params.era ?? S.RC.TExtrinsicEra.immortal
        let hash = try await era.blockHash(substrate: substrate)
        return try hash.asValue().mapContext { id }
    }
}

/// Resource limit check.
public struct DynamicCheckWeightExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct DynamicChargeTransactionPaymentExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        guard let tip = params.tip else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "tip")
        }
        return try tip.asValue().mapContext { id }
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
}

public struct DynamicPrevalidateAttestsExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        Value(value: .sequence([]), context: id)
    }
}
