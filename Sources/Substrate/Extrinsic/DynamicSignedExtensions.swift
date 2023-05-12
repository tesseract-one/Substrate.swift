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
        .nil(id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .u256(UInt256(substrate.runtime.version.specVersion), id)
    }
}

/// Ensure the transaction version registered in the transaction is the same as at present.
public struct DynamicCheckTxVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .u256(UInt256(substrate.runtime.version.transactionVersion), id)
    }
}

/// Check genesis hash
public struct DynamicCheckGenesisExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkGenesis }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .bytes(substrate.runtime.genesisHash.data, id)
    }
}

public struct DynamicCheckNonZeroSenderExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
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
        return .u256(UInt256(nonce), id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
}

/// Check for transaction mortality.
public struct DynamicCheckMortalitySignedExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        guard let era = params.era else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "era")
        }
        return try era.asValue().mapContext { id }
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        guard let hash = params.blockHash else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "blockHash")
        }
        return try hash.asValue().mapContext { id }
    }
}

/// Resource limit check.
public struct DynamicCheckWeightExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
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
        .nil(id)
    }
}

public struct DynamicPrevalidateAttestsExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
    
    public func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId> {
        .nil(id)
    }
}
