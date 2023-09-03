//
//  DynamicExtrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct DynamicCheckSpecVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try api.runtime.version.specVersion.asValue(runtime: api.runtime, type: id)
    }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Nothing.validate(runtime: runtime, type: extra).flatMap {
            SBT<C>.Version.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

///// Ensure the transaction version registered in the transaction is the same as at present.
public struct DynamicCheckTxVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try api.runtime.version.transactionVersion.asValue(runtime: api.runtime, type: id)
    }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Nothing.validate(runtime: runtime, type: extra).flatMap {
            SBT<C>.Version.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

/// Check genesis hash
public struct DynamicCheckGenesisExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkGenesis }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try api.runtime.genesisHash.asValue(runtime: api.runtime, type: id)
    }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Nothing.validate(runtime: runtime, type: extra).flatMap {
            SBT<C>.Hash.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

public struct DynamicCheckNonZeroSenderExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Nothing.validate(runtime: runtime, type: extra).flatMap {
            Nothing.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct DynamicCheckNonceExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonce }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial {
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
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try params.nonce.asValue(runtime: api.runtime, type: id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Compact<AnySigningParams<C>.TPartial.TNonce>.validate(runtime: runtime, type: extra).flatMap {
            Nothing.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

/// Check for transaction mortality.
public struct DynamicCheckMortalityExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial {
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
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try params.era.asValue(runtime: api.runtime, type: id)
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try params.blockHash.asValue(runtime: api.runtime, type: id)
    }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        AnySigningParams<C>.TPartial.TEra.validate(runtime: runtime, type: extra).flatMap {
            AnySigningParams<C>.TPartial.THash.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

/// Resource limit check.
public struct DynamicCheckWeightExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkWeight }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Nothing.validate(runtime: runtime, type: extra).flatMap {
            Nothing.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct DynamicChargeTransactionPaymentExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial {
        var params = params
        if params.tip == nil {
            params.tip = try api.runtime.config.defaultPayment(runtime: api.runtime)
        }
        return params
    }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> {
        try params.tip.asValue(runtime: api.runtime, type: id)
    }

    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        AnySigningParams<C>.TPartial.TPayment.validate(runtime: runtime, type: extra).flatMap {
            Nothing.validate(runtime: runtime, type: additionalSigned)
        }
    }
    
    static func tipType(runtime: any Runtime) -> NetworkType.Info? {
        guard let ext = runtime.metadata.extrinsic.extensions.first(where: {
            $0.identifier == ExtrinsicExtensionId.chargeTransactionPayment.rawValue
        }) else {
            return nil
        }
        return ext.type
    }
}

public struct DynamicPrevalidateAttestsExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
    public init() {}
    
    public func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial { params }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id> { .nil(id) }
    
    public func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError> {
        Nothing.validate(runtime: runtime, type: extra).flatMap {
            Nothing.validate(runtime: runtime, type: additionalSigned)
        }
    }
}
