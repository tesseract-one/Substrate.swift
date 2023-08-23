//
//  EztrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 27/07/2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct CheckSpecVersionExtension<C: BasicConfig, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = SBT<C>.Version
    
    public static var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        .nothing
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws-> TAdditionalSigned where SBC<R.RC> == C {
        api.runtime.version.specVersion
    }
}

///// Ensure the transaction version registered in the transaction is the same as at present.
public struct CheckTxVersionExtension<C: BasicConfig, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = SBT<C>.Version
    
    public static var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial { params }

    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == C {
        api.runtime.version.transactionVersion
    }
}

/// Check genesis hash
public struct CheckGenesisExtension<C: BasicConfig, P: ExtraSigningParameters>: StaticExtrinsicExtension
    where SBT<C>.Hasher: StaticFixedHasher
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = SBT<C>.Hash
    
    public static var identifier: ExtrinsicExtensionId { .checkGenesis }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }
    
    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == C {
        api.runtime.genesisHash
    }
}

public struct CheckNonZeroSenderExtension<C: BasicConfig, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }

    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct CheckNonceExtension<C: BasicConfig, P: NonceSigningParameters>: StaticExtrinsicExtension
    where P.TPartial.TNonce == SBT<C>.Index, P.TPartial.TAccountId == SBT<C>.AccountId
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Compact<P.TPartial.TNonce>
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkNonce }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial where SBC<R.RC> == C {
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
        api: R, params: TParams
    ) async throws -> TExtra {
        Compact(params.nonce)
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Check for transaction mortality.
public struct CheckMortalityExtension<C: BasicConfig, P: EraSigningParameters>: StaticExtrinsicExtension
    where P.TPartial.TEra == SBT<C>.ExtrinsicEra, P.TPartial.THash == SBT<C>.Hash,
          SBT<C>.Hasher: StaticFixedHasher, P.TPartial.TEra: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TPartial.TEra
    public typealias TAdditionalSigned = P.TPartial.THash
    
    public static var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial where SBC<R.RC> == C {
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
        api: R, params: TParams
    ) async throws -> TExtra {
        params.era
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        params.blockHash
    }
}

/// Resource limit check.
public struct CheckWeightExtension<C: BasicConfig, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }

    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct ChargeTransactionPaymentExtension<C: BasicConfig, P: PaymentSigningParameters>: StaticExtrinsicExtension
    where P.TPartial.TPayment == SBT<C>.ExtrinsicPayment, P.TPartial.TPayment: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TPartial.TPayment
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial where SBC<R.RC> == C {
        var params = params
        if params.tip == nil {
            params.tip = try api.runtime.config.defaultPayment(runtime: api.runtime)
        }
        return params
    }
    
    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        return params.tip
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}

public struct PrevalidateAttestsExtension<C: BasicConfig, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public static var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        params
    }

    public func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra {
        .nothing
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        .nothing
    }
}
