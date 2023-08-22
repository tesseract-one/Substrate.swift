//
//  EztrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct CheckSpecVersionExtension<C: Config>: StaticExtrinsicExtension
    where C.TRuntimeVersion.TVersion: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = C.TRuntimeVersion.TVersion
    
    public static var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial { params }
    
    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        .nothing
    }
    
    public func additionalSigned<R: RootApi<C>>(api: R,
                                                params: C.TSigningParams) async throws-> TAdditionalSigned {
        api.runtime.version.specVersion
    }
}

///// Ensure the transaction version registered in the transaction is the same as at present.
public struct CheckTxVersionExtension<C: Config>: StaticExtrinsicExtension
    where C.TRuntimeVersion.TVersion: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = C.TRuntimeVersion.TVersion
    
    public static var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial { params }

    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        api.runtime.version.transactionVersion
    }
}

/// Check genesis hash
public struct CheckGenesisExtension<C: Config>: StaticExtrinsicExtension
    where C.THasher: StaticFixedHasher
{
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = C.THasher.THash
    
    public static var identifier: ExtrinsicExtensionId { .checkGenesis }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        params
    }
    
    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        api.runtime.genesisHash
    }
}

public struct CheckNonZeroSenderExtension<C: Config>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        params
    }

    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct CheckNonceExtension<C: Config>: StaticExtrinsicExtension
    where C.TSigningParams: NonceSigningParameters,
          C.TSigningParams.TPartial.TNonce == C.TIndex,
          C.TSigningParams.TPartial.TAccountId == C.TAccountId
{
    public typealias TConfig = C
    public typealias TExtra = Compact<C.TSigningParams.TPartial.TNonce>
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkNonce }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        guard params.nonce == nil else { return params }
        guard let account = params.account else {
            throw ExtrinsicCodingError.parameterNotFound(extension: Self.identifier,
                                                         parameter: "account")
        }
        var params = params
        let nextIndex = try await api.client.accountNextIndex(id: account,
                                                              runtime: api.runtime)
        params.nonce = nextIndex
        return params
    }

    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        Compact(params.nonce)
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Check for transaction mortality.
public struct CheckMortalityExtension<C: Config>: StaticExtrinsicExtension
    where C.TSigningParams: EraSigningParameters,
          C.TSigningParams.TPartial.TEra == C.TExtrinsicEra,
          C.TSigningParams.TPartial.THash == C.THasher.THash,
          C.THasher: StaticFixedHasher, C.TExtrinsicEra: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TExtra = C.TSigningParams.TPartial.TEra
    public typealias TAdditionalSigned = C.TSigningParams.TPartial.THash
    
    public static var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        var params = params
        if params.era == nil {
            params.era = .immortal
        }
        if params.blockHash == nil {
            params.blockHash = try await params.era!.blockHash(api: api)
        }
        return params
    }

    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        params.era
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        params.blockHash
    }
}

/// Resource limit check.
public struct CheckWeightExtension<C: Config>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        params
    }

    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct ChargeTransactionPaymentExtension<C: Config>: StaticExtrinsicExtension
    where C.TSigningParams: PaymentSigningParameters,
          C.TSigningParams.TPartial.TPayment == C.TExtrinsicPayment,
          C.TExtrinsicPayment: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TExtra = C.TSigningParams.TPartial.TPayment
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        var params = params
        if params.tip == nil {
            params.tip = try api.runtime.config.defaultPayment(runtime: api.runtime)
        }
        return params
    }
    
    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        return params.tip
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

public struct PrevalidateAttestsExtension<C: Config>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public init() {}
    
    public func params<R: RootApi<C>>(
        api: R, partial params: C.TSigningParams.TPartial
    ) async throws -> C.TSigningParams.TPartial {
        params
    }

    public func extra<R: RootApi<C>>(api: R, params: C.TSigningParams) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi<C>>(
        api: R, params: C.TSigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}
