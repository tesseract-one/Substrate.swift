//
//  DynamicSignedExtensions.swift
//
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

public protocol DynamicExtrinsicExtension {
    var identifier: ExtrinsicExtensionId { get }
    
    func params<R: RootApi>(
        api: R, partial params: AnySigningParams<R.RC>.TPartial
    ) async throws -> AnySigningParams<R.RC>.TPartial
    
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
    
    public let extensions: [String: DynamicExtrinsicExtension]
    public let version: UInt8
    
    private var _extraType: RuntimeType.Id!
    private var _additionalSignedTypes: [RuntimeType.Id]!
    private weak var _runtime: (any Runtime)!
    private var _params: ((TSigningParams.Partial) async throws -> TSigningParams.Partial)!
    private var _extra: ((TSigningParams) async throws -> TExtra)!
    private var _additionalSigned: ((TSigningParams) async throws -> TAdditionalSigned)!
    
    public init(extensions: [DynamicExtrinsicExtension], version: UInt8) {
        self.extensions = Dictionary(uniqueKeysWithValues: extensions.map { ($0.identifier.rawValue, $0) })
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
        let extensions = try api.runtime.metadata.extrinsic.extensions.map { info in
            guard let ext = self.extensions[info.identifier] else {
                throw  ExtrinsicCodingError.unknownExtension(identifier: info.identifier)
            }
            return (ext: ext, eId: info.type.id, aId: info.additionalSigned.id)
        }
        self._params = { [unowned api] params in
            var params = params
            for ext in extensions {
                params = try await ext.ext.params(api: api, partial: params)
            }
            return params
        }
        self._extra = { [unowned api] params in
            var extra: [Value<RuntimeType.Id>] = []
            extra.reserveCapacity(extensions.count)
            for ext in extensions {
                try await extra.append(ext.ext.extra(api: api, params: params, id: ext.eId))
            }
            return Value(value: .sequence(extra), context: extraType)
        }
        self._additionalSigned = { [unowned api] params in
            var extra: [Value<RuntimeType.Id>] = []
            extra.reserveCapacity(extensions.count)
            for ext in extensions {
                try await extra.append(ext.ext.additionalSigned(api: api, params: params, id: ext.aId))
            }
            return extra
        }
        self._extraType = extraType
        self._additionalSignedTypes = extensions.map { $0.aId }
        self._runtime = api.runtime
    }
}
