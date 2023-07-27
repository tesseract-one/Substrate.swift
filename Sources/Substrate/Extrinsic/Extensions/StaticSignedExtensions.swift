//
//  StaticSignedExtensions.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import Tuples
import ScaleCodec


public class StaticSignedExtensionsProvider<Ext: StaticExtrinsicExtension>: SignedExtensionsProvider {
    public typealias RC = Ext.TConfig
    public typealias TExtra = Ext.TExtra
    public typealias TAdditionalSigned = Ext.TAdditionalSigned
    public typealias TSigningParams = Ext.TParams
    
    public let extensions: Ext
    public let version: UInt8
    
    private var _extra: ((TSigningParams) async throws -> TExtra)!
    private var _addSigned: ((TSigningParams) async throws -> TAdditionalSigned)!
    private weak var _runtime: (any Runtime)!
    
    public init(extensions: Ext, version: UInt8) {
        self.extensions = extensions
        self.version = version
    }
    
    public func params(overrides params: TSigningParams?) async throws -> TSigningParams {
        try .default.override(overrides: params)
    }
    
    public func extra(params: TSigningParams) async throws -> TExtra {
        try await _extra(params)
    }
    
    public func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned {
        try await _addSigned(params)
    }
    
    public func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E) throws {
        try extra.encode(in: &encoder, runtime: _runtime)
    }
    
    public func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned,
                                              in encoder: inout E) throws
    {
        try additionalSigned.encode(in: &encoder, runtime: _runtime)
    }
    
    public func extra<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TExtra {
        try TExtra(from: &decoder, runtime: _runtime)
    }
    
    public func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TAdditionalSigned  {
        try TAdditionalSigned(from: &decoder, runtime: _runtime)
    }
    
    public func setRootApi<R: RootApi>(api: R) throws where RC == R.RC {
        guard api.runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: api.runtime.metadata.extrinsic.version)
        }
        let metaExtNames = api.runtime.metadata.extrinsic.extensions.map { $0.identifier }
        let extNames = extensions.identifier.map { $0.rawValue }
        guard extNames == metaExtNames else {
            throw ExtrinsicCodingError.badExtras(expected: metaExtNames, got: extensions.identifier)
        }
        self._runtime = api.runtime
        let ext = self.extensions
        self._extra = { [unowned api] params in
            try await ext.extra(api: api, params: params)
        }
        self._addSigned = { [unowned api] params in
            try await ext.additionalSigned(api: api, params: params)
        }
    }
}

public protocol StaticExtrinsicExtension<TConfig, TParams> {
    associatedtype TConfig: Config
    associatedtype TParams: ExtraSigningParameters
    associatedtype TExtra: RuntimeCodable
    associatedtype TAdditionalSigned: RuntimeCodable
    
    func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    
    var identifier: [ExtrinsicExtensionId] { get }
}

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct CheckSpecVersionExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = UInt32
    
    public var identifier: [ExtrinsicExtensionId] { [.checkSpecVersion] }
    
    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        .nothing
    }
    
    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws-> TAdditionalSigned
        where R.RC == TConfig
    {
        api.runtime.version.specVersion
    }
}
//
///// Ensure the transaction version registered in the transaction is the same as at present.
public struct CheckTxVersionExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = UInt32
    
    public var identifier: [ExtrinsicExtensionId] { [.checkTxVersion] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        .nothing
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        api.runtime.version.transactionVersion
    }
}

/// Check genesis hash
public struct CheckGenesisExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension
    where C.THasher: StaticFixedHasher
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = C.THasher.THash
    
    public var identifier: [ExtrinsicExtensionId] { [.checkGenesis] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        .nothing
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        api.runtime.genesisHash
    }
}

public struct CheckNonZeroSenderExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: [ExtrinsicExtensionId] { [.checkNonZeroSender] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        .nothing
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        .nothing
    }
}

/// Nonce check and increment to give replay protection for transactions.
public struct CheckNonceExtension<C: Config, P: NonceSigningParameter>: StaticExtrinsicExtension
    where P.TNonce == C.TIndex
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TNonce
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: [ExtrinsicExtensionId] { [.checkNonce] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        guard let nonce = params.nonce else {
            throw ExtrinsicCodingError.parameterNotFound(extension: .checkNonce,
                                                         parameter: "nonce")
        }
        return nonce
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        .nothing
    }
}

/// Check for transaction mortality.
public struct CheckMortalitySignedExtension<C: Config, P: EraSigningParameter>: StaticExtrinsicExtension
    where P.TEra == C.TExtrinsicEra, P.THash == C.THasher.THash,
          C.THasher: StaticFixedHasher, C.TExtrinsicEra: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TEra
    public typealias TAdditionalSigned = P.THash
    
    public var identifier: [ExtrinsicExtensionId] { [.checkMortality] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        guard let era = params.era else {
            throw ExtrinsicCodingError.parameterNotFound(extension: .checkMortality,
                                                         parameter: "era")
        }
        return era
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        guard let hash = params.blockHash else {
            throw ExtrinsicCodingError.parameterNotFound(extension: .checkMortality,
                                                         parameter: "blockHash")
        }
        return hash
    }
}

/// Resource limit check.
public struct CheckWeightExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: [ExtrinsicExtensionId] { [.checkWeight] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        .nothing
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        .nothing
    }
}

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct ChargeTransactionPaymentExtension<C: Config, P: PaymentSigningParameter>: StaticExtrinsicExtension
    where P.TPayment == C.TExtrinsicPayment, C.TExtrinsicPayment: RuntimeCodable
{
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = P.TPayment
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: [ExtrinsicExtensionId] { [.chargeTransactionPayment] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        guard let tip = params.tip else {
            throw ExtrinsicCodingError.parameterNotFound(extension: .chargeTransactionPayment,
                                                         parameter: "tip")
        }
        return tip
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        .nothing
    }
}

public struct PrevalidateAttestsExtension<C: Config, P: ExtraSigningParameters>: StaticExtrinsicExtension {
    public typealias TConfig = C
    public typealias TParams = P
    public typealias TExtra = Nothing
    public typealias TAdditionalSigned = Nothing
    
    public var identifier: [ExtrinsicExtensionId] { [.prevalidateAttests] }

    public func extra<R: RootApi>(api: R, params: TParams) async throws -> TExtra
        where R.RC == TConfig
    {
        .nothing
    }

    public func additionalSigned<R: RootApi>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R.RC == TConfig
    {
        .nothing
    }
}
