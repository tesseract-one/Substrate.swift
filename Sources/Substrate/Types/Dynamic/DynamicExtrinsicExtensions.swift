//
//  DynamicExtrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

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
