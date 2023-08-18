//
//  DynamicSignedExtensions.swift
//
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

public protocol DynamicExtrinsicExtension<TConfig>: ExtrinsicSignedExtension {
    associatedtype TConfig: Config
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: AnySigningParams<TConfig>.TPartial
    ) async throws -> AnySigningParams<TConfig>.TPartial

    func extra<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id>

    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id>
}

public protocol DynamicExtrinsicExtensions<TConfig> {
    associatedtype TConfig: Config
    
    var identifiers: [ExtrinsicExtensionId] { get }
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: AnySigningParams<TConfig>.TPartial,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> AnySigningParams<TConfig>.TPartial
    
    func extra<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> [ExtrinsicExtensionId: Value<RuntimeType.Id>]
    
    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> [ExtrinsicExtensionId: Value<RuntimeType.Id>]
}

public class DynamicSignedExtensionsProvider<Ext: DynamicExtrinsicExtensions>: SignedExtensionsProvider {
    public typealias RC = Ext.TConfig
    public typealias TExtra = Value<RuntimeType.Id>
    public typealias TAdditionalSigned = [Value<RuntimeType.Id>]
    public typealias TSigningParams = AnySigningParams<RC>
    
    public let extensions: Ext
    public let version: UInt8
    
    private var _extraType: RuntimeType.Id!
    private var _additionalSignedTypes: [RuntimeType.Id]!
    private weak var _runtime: (any Runtime)!
    private var _params: ((TSigningParams.Partial) async throws -> TSigningParams.Partial)!
    private var _extra: ((TSigningParams) async throws -> TExtra)!
    private var _additionalSigned: ((TSigningParams) async throws -> TAdditionalSigned)!
    
    public init(extensions: Ext, version: UInt8) {
        self.extensions = extensions
        self.version = version
    }
    
    public func params(partial params: TSigningParams.Partial) async throws -> TSigningParams {
        try await TSigningParams(partial: _params(params))
    }
        
    public func extra(params: TSigningParams) async throws -> TExtra {
        try await _extra(params)
    }
    
    public func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned {
        try await _additionalSigned(params)
    }
    
    public func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E) throws {
        try extra.encode(in: &encoder, runtime: _runtime)
    }
    
    public func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned, in encoder: inout E) throws {
        guard additionalSigned.count == _additionalSignedTypes.count else {
            throw ExtrinsicCodingError.badExtrasCount(expected: _additionalSignedTypes.count,
                                                      got: additionalSigned.count)
        }
        for ext in additionalSigned {
            try ext.encode(in: &encoder, runtime: _runtime)
        }
    }
    
    public func extra<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TExtra {
        try TExtra(from: &decoder, as: _extraType, runtime: _runtime)
    }
    
    public func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TAdditionalSigned {
        try _additionalSignedTypes.map { tId in
            try Value(from: &decoder, as: tId, runtime: _runtime)
        }
    }
    
    public func setRootApi<R: RootApi<RC>>(api: R) throws {
        guard api.runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: api.runtime.metadata.extrinsic.version)
        }
        let extraType = try api.runtime.types.extrinsicExtra.id
        let allExtensions = extensions
        let extrinsicExtensions = api.runtime.metadata.extrinsic.extensions.map {
            (key: ExtrinsicExtensionId($0.identifier),
             value: (extId: $0.type.id, addId: $0.additionalSigned.id))
        }
        let unknown = Set(extrinsicExtensions.map{$0.key}).subtracting(allExtensions.identifiers)
        guard unknown.count == 0 else {
            throw ExtrinsicCodingError.unknownExtension(identifier: unknown.first!)
        }
        let extrinsicExtensionsMap = Dictionary(uniqueKeysWithValues: extrinsicExtensions)
        self._params = { [unowned api] params in
            try await allExtensions.params(api: api, partial: params,
                                           extensions: extrinsicExtensionsMap)
        }
        self._extra = { [unowned api] params in
            let extraMap = try await allExtensions.extra(api: api, params: params,
                                                         extensions: extrinsicExtensionsMap)
            var extra: [Value<RuntimeType.Id>] = []
            extra.reserveCapacity(extrinsicExtensions.count)
            for ext in extrinsicExtensions {
                extra.append(extraMap[ext.key]!)
            }
            return Value(value: .sequence(extra), context: extraType)
        }
        self._additionalSigned = { [unowned api] params in
            let addMap = try await allExtensions.additionalSigned(api: api, params: params,
                                                                  extensions: extrinsicExtensionsMap)
            var additional: [Value<RuntimeType.Id>] = []
            additional.reserveCapacity(extrinsicExtensions.count)
            for ext in extrinsicExtensions {
                additional.append(addMap[ext.key]!)
            }
            return additional
        }
        self._extraType = extraType
        self._additionalSignedTypes = extrinsicExtensions.map { $0.value.addId }
        self._runtime = api.runtime
    }
}

public extension DynamicExtrinsicExtension where
    Self: StaticExtrinsicExtensionBase, TParams == AnySigningParams<TConfig>,
    TExtra: ValueRepresentable, TAdditionalSigned: ValueRepresentable
{
    func extra<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        try await extra(api: api, params: params).asValue(runtime: api.runtime, type: id)
    }

    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>, id: RuntimeType.Id
    ) async throws -> Value<RuntimeType.Id> {
        try await additionalSigned(api: api, params: params).asValue(runtime: api.runtime, type: id)
    }
}
