//
//  EztrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct CheckSpecVersionExtension<C: BasicConfig>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = SBT<C>.Version
    
    public static var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        .nothing
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws-> TAdditionalSigned where SBC<R.RC> == C {
        api.runtime.version.specVersion
    }
}

///// Ensure the transaction version registered in the transaction is the same as at present.
public struct CheckTxVersionExtension<C: BasicConfig>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = SBT<C>.Version
    
    public static var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial { params }

    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == C {
        api.runtime.version.transactionVersion
    }
}

/// Check genesis hash
public struct CheckGenesisExtension<C: BasicConfig>: StaticExtrinsicExtension
    where SBT<C>.Hasher: StaticFixedHasher
{
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = SBT<C>.Hash
    
    public static var identifier: ExtrinsicExtensionId { .checkGenesis }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == C {
        api.runtime.genesisHash
    }
}

public struct CheckNonZeroSenderExtension<C: BasicConfig>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial {
        params
    }

    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct CheckNonceExtension<C: BasicConfig>: StaticExtrinsicExtension
    where SBT<C>.SigningParams: NonceSigningParameters,
          SBT<C>.SigningParamsPartial.TNonce == SBT<C>.Index,
          SBT<C>.SigningParamsPartial.TAccountId == SBT<C>.AccountId
{
    public typealias TConfig = C
    public typealias TExtra = Compact<SBT<C>.SigningParamsPartial.TNonce>
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkNonce }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial where SBC<R.RC> == C {
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

    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        Compact(params.nonce)
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Check for transaction mortality.
public struct CheckMortalityExtension<C: BasicConfig>: StaticExtrinsicExtension
    where SBT<C>.SigningParams: EraSigningParameters,
          SBT<C>.SigningParamsPartial.TEra == SBT<C>.ExtrinsicEra,
          SBT<C>.SigningParamsPartial.THash == SBT<C>.Hash,
          SBT<C>.Hasher: StaticFixedHasher, SBT<C>.ExtrinsicEra: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TExtra = SBT<C>.SigningParamsPartial.TEra
    public typealias TAdditionalSigned = SBT<C>.SigningParamsPartial.THash
    
    public static var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial where SBC<R.RC> == C {
        var params = params
        if params.era == nil {
            params.era = .immortal
        }
        if params.blockHash == nil {
            params.blockHash = try await params.era!.blockHash(api: api)
        }
        return params
    }

    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        params.era
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned {
        params.blockHash
    }
}

/// Resource limit check.
public struct CheckWeightExtension<C: BasicConfig>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial {
        params
    }

    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct ChargeTransactionPaymentExtension<C: BasicConfig>: StaticExtrinsicExtension
    where SBT<C>.SigningParams: PaymentSigningParameters,
          SBT<C>.SigningParamsPartial.TPayment == SBT<C>.ExtrinsicPayment,
          SBT<C>.ExtrinsicPayment: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TExtra = SBT<C>.SigningParamsPartial.TPayment
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial where SBC<R.RC> == C {
        var params = params
        if params.tip == nil {
            params.tip = try api.runtime.config.defaultPayment(runtime: api.runtime)
        }
        return params
    }
    
    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        return params.tip
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

public struct PrevalidateAttestsExtension<C: BasicConfig>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: SBT<C>.SigningParamsPartial
    ) async throws -> SBT<C>.SigningParamsPartial {
        params
    }

    public func extra<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: SBT<C>.SigningParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}
