//
//  DynamicSignedExtensions.swift
//
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

public struct AnySigningParams<RT: Config>: ExtraSigningParameters {
    private var params: [String: Any]
    
    public init() {
        self.params = [:]
    }
    
    public func override(overrides: Self?) throws -> Self {
        guard let overrides = overrides else { return self }
        var params = self
        for (key, val) in overrides.params {
            params[key] = val
        }
        return params
    }
    
    public static var `default`: Self { Self() }
    
    public subscript(key: String) -> Any? {
        get { params[key] }
        set { params[key] = newValue }
    }
}

extension AnySigningParams: NonceSigningParameter {
    public typealias TNonce = RT.TIndex
    public var nonce: TNonce? {
        get { self["nonce"] as? TNonce }
        set { self["nonce"] = newValue }
    }
    public func nonce(_ nonce: TNonce) -> Self {
        var new = self
        new.nonce = nonce
        return new
    }
    public static func nonce(_ nonce: TNonce) -> Self {
        var new = Self()
        new.nonce = nonce
        return new
    }
}

extension AnySigningParams: EraSigningParameter {
    public typealias TEra = RT.TExtrinsicEra
    public typealias THash = RT.TBlock.THeader.THasher.THash
    public var era: TEra? {
        get { params["era"] as? TEra }
        set { params["era"] = newValue }
    }
    public func era(_ era: TEra) -> Self {
        var new = self
        new.era = era
        return new
    }
    public static func era(_ era: TEra) -> Self {
        var new = Self()
        new.era = era
        return new
    }
    public var blockHash: THash? {
        get { params["blockHash"] as? THash }
        set { params["blockHash"] = newValue }
    }
    public func blockHash(_ hash: THash) -> Self {
        var new = self
        new.blockHash = hash
        return new
    }
    public static func blockHash(_ hash: THash) -> Self {
        var new = Self()
        new.blockHash = hash
        return new
    }
}

extension AnySigningParams: PaymentSigningParameter {
    public typealias TPayment = RT.TExtrinsicPayment
    public var tip: TPayment? {
        get { self["tip"] as? TPayment }
        set { self["tip"] = newValue }
    }
    public func tip(_ tip: TPayment) -> Self {
        var new = self
        new.tip = tip
        return new
    }
    public static func tip(_ tip: TPayment) -> Self {
        var new = Self()
        new.tip = tip
        return new
    }
}

public protocol DynamicExtrinsicExtension {
    var identifier: ExtrinsicExtensionId { get }
    
    func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id>
    
    func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id>
}

public class DynamicSignedExtensionsProvider<RC: Config>: SignedExtensionsProvider {
    public typealias RC = RC
    public typealias TExtra = Value<RuntimeType.Id>
    public typealias TAdditionalSigned = [Value<RuntimeType.Id>]
    public typealias TSigningParams = AnySigningParams<RC>
    
    private var _api: (any _RootApiWrapper<RC>)!
    
    public let extensions: [String: DynamicExtrinsicExtension]
    public let version: UInt8
    
    public init(extensions: [DynamicExtrinsicExtension], version: UInt8) {
        self.extensions = Dictionary(uniqueKeysWithValues: extensions.map { ($0.identifier.rawValue, $0) })
        self.version = version
    }
    
    public func params(overrides params: TSigningParams?) async throws -> TSigningParams {
        try .default.override(overrides: params)
    }
    
    public func defaultParams() async throws -> TSigningParams { AnySigningParams() }
    
    public func extra(params: TSigningParams) async throws -> TExtra {
        try await _api.extra(params: params)
    }
    
    public func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned {
        try await _api.additionalSigned(params: params)
    }
    
    public func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E) throws {
        try extra.encode(in: &encoder, runtime: _api.runtime)
    }
    
    public func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned, in encoder: inout E) throws {
        guard additionalSigned.count == _api.additionalSignedTypes.count else {
            throw ExtrinsicCodingError.badExtrasCount(expected: _api.additionalSignedTypes.count,
                                                      got: additionalSigned.count)
        }
        for ext in additionalSigned {
            try ext.encode(in: &encoder, runtime: _api.runtime)
        }
    }
    
    public func extra<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TExtra {
        try TExtra(from: &decoder, as: _api.extraType, runtime: _api.runtime)
    }
    
    public func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TAdditionalSigned {
        try _api.additionalSignedTypes.map { tId in
            try Value(from: &decoder, as: tId, runtime: _api.runtime)
        }
    }
    
    public func setRootApi<R: RootApi<RC>>(api: R) throws {
        self._api = try _ApiWrapper(api: api, version: version, extensions: extensions)
    }
}

/// Ensure the runtime version registered in the transaction is the same as at present.
public struct DynamicCheckSpecVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkSpecVersion }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .u256(UInt256(api.runtime.version.specVersion), id)
    }
}

/// Ensure the transaction version registered in the transaction is the same as at present.
public struct DynamicCheckTxVersionExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkTxVersion }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .u256(UInt256(api.runtime.version.transactionVersion), id)
    }
}

/// Check genesis hash
public struct DynamicCheckGenesisExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkGenesis }
    
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

public struct DynamicCheckNonZeroSenderExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonZeroSender }
    
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

/// Nonce check and increment to give replay protection for transactions.
public struct DynamicCheckNonceExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkNonce }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        guard let nonce = params.nonce else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "nonce")
        }
        return .u256(UInt256(nonce), id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

/// Check for transaction mortality.
public struct DynamicCheckMortalitySignedExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkMortality }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        guard let era = params.era else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "era")
        }
        return try era.asValue(runtime: api.runtime, type: id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        guard let hash = params.blockHash else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "blockHash")
        }
        return try hash.asValue(runtime: api.runtime, type: id)
    }
}

/// Resource limit check.
public struct DynamicCheckWeightExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .checkWeight }
    
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

/// Require the transactor pay for themselves and maybe include a tip to gain additional priority
/// in the queue.
public struct DynamicChargeTransactionPaymentExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .chargeTransactionPayment }
    
    public func extra<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        guard let tip = params.tip else {
            throw ExtrinsicCodingError.parameterNotFound(extension: identifier,
                                                         parameter: "tip")
        }
        return try tip.asValue(runtime: api.runtime, type: id)
    }
    
    public func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<R.RC>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        .nil(id)
    }
}

public struct DynamicPrevalidateAttestsExtension: DynamicExtrinsicExtension {
    public var identifier: ExtrinsicExtensionId { .prevalidateAttests }
    
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

private protocol _RootApiWrapper<RC> {
    associatedtype RC: Config
    
    var extraType: RuntimeType.Id { get }
    var additionalSignedTypes: [RuntimeType.Id] { get }
    var runtime: any Runtime { get }
    
    func extra(params: AnySigningParams<RC>) async throws -> Value<RuntimeType.Id>
    func additionalSigned(params: AnySigningParams<RC>) async throws -> [Value<RuntimeType.Id>]
}

private struct _ApiWrapper<R: RootApi>: _RootApiWrapper {
    typealias RC = R.RC
    
    weak var api: R!
    let extensions: [(ext: DynamicExtrinsicExtension, eId: RuntimeType.Id, aId: RuntimeType.Id)]
    
    let extraType: RuntimeType.Id
    let additionalSignedTypes: [RuntimeType.Id]
    @inlinable
    var runtime: any Runtime { api.runtime }
    
    init(api: R, version: UInt8, extensions: [String: DynamicExtrinsicExtension]) throws {
        guard api.runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: api.runtime.metadata.extrinsic.version)
        }
        self.extraType = try api.runtime.types.extrinsicExtra.id
        self.extensions = try api.runtime.metadata.extrinsic.extensions.map { info in
            guard let ext = extensions[info.identifier] else {
                throw  ExtrinsicCodingError.unknownExtension(identifier: info.identifier)
            }
            return (ext, info.type.id, info.additionalSigned.id)
        }
        self.additionalSignedTypes = self.extensions.map { $0.aId }
        self.api = api
    }
    
    func extra(params: AnySigningParams<R.RC>) async throws -> Value<RuntimeType.Id> {
        var extra: [Value<RuntimeType.Id>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.ext.extra(api: api, params: params, id: ext.eId))
        }
        return Value(value: .sequence(extra), context: extraType)
    }
    
    func additionalSigned(params: AnySigningParams<R.RC>) async throws -> [Value<RuntimeType.Id>] {
        var extra: [Value<RuntimeType.Id>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.ext.additionalSigned(api: api, params: params, id: ext.aId))
        }
        return extra
    }
}
