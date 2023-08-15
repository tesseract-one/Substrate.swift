//
//  EztrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct CheckSpecVersionExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = UInt32
    
    public var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial { params }
    
    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        .nothing
    }
    
    public func additionalSigned<R: RootApi<C>>(api: R, params: TParams) async throws-> TAdditionalSigned {
        api.runtime.version.specVersion
    }
}

extension CheckSpecVersionExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .uint(UInt256(api.runtime.version.specVersion), id)
    }
}

public typealias DynamicCheckSpecVersionExtension<C: Config> = CheckSpecVersionExtension<C, AnySigningParams<C>>

///// Ensure the transaction version registered in the transaction is the same as at present.
public struct CheckTxVersionExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = UInt32
    
    public var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial { params }

    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        api.runtime.version.transactionVersion
    }
}

extension CheckTxVersionExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .uint(UInt256(api.runtime.version.transactionVersion), id)
    }
}

public typealias DynamicCheckTxVersionExtension<C: Config> = CheckTxVersionExtension<C, AnySigningParams<C>>

/// Check genesis hash
public struct CheckGenesisExtension<C: Config, P: ExtraSigningParameters> {
    public var identifier: ExtrinsicExtensionId { .checkGenesis }
}

extension CheckGenesisExtension: StaticExtrinsicExtension, StaticExtrinsicExtensionBase
    where C.THasher: StaticFixedHasher
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = C.THasher.THash
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }
    
    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        api.runtime.genesisHash
    }
}

extension CheckGenesisExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        try api.runtime.genesisHash.asValue(runtime: api.runtime, type: id)
    }
}

public typealias DynamicCheckGenesisExtension<C: Config> = CheckGenesisExtension<C, AnySigningParams<C>>

public struct CheckNonZeroSenderExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }

    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

extension CheckNonZeroSenderExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

public typealias DynamicCheckNonZeroSenderExtension<C: Config> = CheckNonZeroSenderExtension<C, AnySigningParams<C>>

/// Nonce check and increment to give replay protection for transactions.
public struct CheckNonceExtension<C: Config, P: NonceSigningParameters> {
    public var identifier: ExtrinsicExtensionId { .checkNonce }
    
    func params<R: RootApi, PR: NonceSigningParameters>(
        api: R, partial params: PR.TPartial, ptype: PR.Type
    ) async throws -> PR.TPartial where
        PR.TPartial.TNonce == R.RC.TIndex, PR.TPartial.TAccountId == R.RC.TAccountId
    {
        guard params.nonce == nil else { return params }
        guard let account = params.account else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "account")
        }
        var params = params
        let nextIndex = try await api.client.accountNextIndex(id: account,
                                                              runtime: api.runtime)
        params.nonce = nextIndex
        return params
    }
}

extension CheckNonceExtension: StaticExtrinsicExtension, StaticExtrinsicExtensionBase
    where P.TPartial.TNonce == C.TIndex, P.TPartial.TAccountId == C.TAccountId
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TPartial.TNonce
    public typealias TAdditionalSigned = Nothing
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        try await self.params(api: api, partial: params, ptype: TParams.self)
    }

    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        params.nonce
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

extension CheckNonceExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        try await self.params(api: api, partial: params, ptype: AnySigningParams<R.RC>.self)
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .uint(UInt256(params.nonce), id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

public typealias DynamicCheckNonceExtension<C: Config> = CheckNonceExtension<C, AnySigningParams<C>>

/// Check for transaction mortality.
public struct CheckMortalitySignedExtension<C: Config, P: EraSigningParameters> {
    public var identifier: ExtrinsicExtensionId { .checkMortality }
    
    func params<R: RootApi, PR: EraSigningParameters>(
        api: R, partial params: PR.TPartial, ptype: PR.Type
    ) async throws -> PR.TPartial where
        R.RC.THasher.THash == PR.TPartial.THash
    {
        var params = params
        if params.era == nil {
            params.era = .immortal
        }
        if params.blockHash == nil {
            params.blockHash = try await params.era!.blockHash(api: api)
        }
        return params
    }
}

extension CheckMortalitySignedExtension: StaticExtrinsicExtension, StaticExtrinsicExtensionBase
    where P.TPartial.TEra == C.TExtrinsicEra, P.TPartial.THash == C.THasher.THash,
          C.THasher: StaticFixedHasher, C.TExtrinsicEra: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TPartial.TEra
    public typealias TAdditionalSigned = P.TPartial.THash
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> P.TPartial {
        try await self.params(api: api, partial: params, ptype: TParams.self)
    }

    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        params.era
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        params.blockHash
    }
}

extension CheckMortalitySignedExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        try await self.params(api: api, partial: params, ptype: AnySigningParams<R.RC>.self)
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        return try params.era.asValue(runtime: api.runtime, type: id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        return try params.blockHash.asValue(runtime: api.runtime, type: id)
    }
}

public typealias DynamicCheckMortalitySignedExtension<C: Config> = CheckMortalitySignedExtension<C, AnySigningParams<C>>

/// Resource limit check.
public struct CheckWeightExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }

    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

extension CheckWeightExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

public typealias DynamicCheckWeightExtension<C: Config> = CheckWeightExtension<C, AnySigningParams<C>>

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct ChargeTransactionPaymentExtension<C: Config, P: PaymentSigningParameters> {
    public var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    func params<R: RootApi, PR: PaymentSigningParameters>(
        api: R, partial params: PR.TPartial, ptype: PR.Type
    ) async throws -> PR.TPartial {
        var params = params
        if params.tip == nil {
            params.tip = .default
        }
        return params
    }
}
extension ChargeTransactionPaymentExtension: StaticExtrinsicExtension, StaticExtrinsicExtensionBase
    where P.TPartial.TPayment == C.TExtrinsicPayment, C.TExtrinsicPayment: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TPartial.TPayment
    public typealias TAdditionalSigned = Nothing
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        try await self.params(api: api, partial: params, ptype: TParams.self)
    }
    
    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        return params.tip
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

extension ChargeTransactionPaymentExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        try await self.params(api: api, partial: params, ptype: AnySigningParams<R.RC>.self)
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        return try params.tip.asValue(runtime: api.runtime, type: id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

public typealias DynamicChargeTransactionPaymentExtension<C: Config> =
    ChargeTransactionPaymentExtension<C, AnySigningParams<C>>


public struct PrevalidateAttestsExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public func params<R: RootApi<C>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }

    public func extra<R: RootApi<C>>(api: R, params: TParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

extension PrevalidateAttestsExtension: DynamicExtrinsicExtension where P == AnySigningParams<TConfig> {
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

public typealias DynamicPrevalidateAttestsExtension<C: Config> =
    PrevalidateAttestsExtension<C, AnySigningParams<C>>
