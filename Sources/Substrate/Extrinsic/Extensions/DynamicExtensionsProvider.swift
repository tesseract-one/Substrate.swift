//
//  DynamicSignedExtensions.swift
//
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

public protocol DynamicExtrinsicExtension: ExtrinsicSignedExtension {
    func params<R: RootApi>(
        api: R, partial params: AnySigningParams<SBC<R.RC>>.TPartial
    ) async throws -> AnySigningParams<SBC<R.RC>>.TPartial

    func extra<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id>

    func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, id: NetworkType.Id
    ) async throws -> Value<NetworkType.Id>
    
    func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: NetworkType.Info, additionalSigned: NetworkType.Info
    ) -> Result<Void, TypeError>
}

public extension DynamicExtrinsicExtension {
    @inlinable
    func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra eId: NetworkType.Id,
        additionalSigned aId: NetworkType.Id
    ) -> Result<Void, TypeError> {
        guard let eType = runtime.resolve(type: eId) else {
            return .failure(.typeNotFound(for: Self.self, id: eId))
        }
        guard let aType = runtime.resolve(type: aId) else {
            return .failure(.typeNotFound(for: Self.self, id: aId))
        }
        return validate(config: config, runtime: runtime,
                        extra: eId.i(eType), additionalSigned: aId.i(aType))
    }
}

public class DynamicSignedExtensionsProvider<BC: BasicConfig>: SignedExtensionsProvider {
    public typealias TConfig = BC
    public typealias TParams = AnySigningParams<BC>
    public typealias TExtra = Value<NetworkType.Id>
    public typealias TAdditionalSigned = [Value<NetworkType.Id>]
    
    public let extensions: [ExtrinsicExtensionId: any DynamicExtrinsicExtension]
    public let version: UInt8
    
    public init(extensions: [any DynamicExtrinsicExtension], version: UInt8) {
        self.extensions = Dictionary(uniqueKeysWithValues: extensions.map { ($0.identifier, $0) })
        self.version = version
    }
    
    public func params<R: RootApi>(
        partial params: TParams.TPartial, for api: R
    ) async throws -> TParams where SBC<R.RC> == TConfig {
        var params = params
        for ext in try _activeExtensions(runtime: api.runtime).get() {
            params = try await ext.ext.params(api: api, partial: params)
        }
        return try TParams(partial: params)
    }
        
    public func extra<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TExtra where SBC<R.RC> == TConfig {
        let extensions = try _activeExtensions(runtime: api.runtime).get()
        var extra: [Value<NetworkType.Id>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.ext.extra(api: api, params: params, id: ext.extId))
        }
        return try Value(value: .sequence(extra), context: api.runtime.types.extrinsicExtra.id)
    }
    
    public func additionalSigned<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig {
        let extensions = try _activeExtensions(runtime: api.runtime).get()
        var additional: [Value<NetworkType.Id>] = []
        additional.reserveCapacity(extensions.count)
        for ext in extensions {
            try await additional.append(ext.ext.additionalSigned(api: api, params: params, id: ext.addId))
        }
        return additional
    }
    
    public func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E,
                                              runtime: any Runtime) throws {
        try runtime.encode(value: extra, in: &encoder,
                           as: runtime.types.extrinsicExtra.id)
    }
    
    public func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned,
                                              in encoder: inout E,
                                              runtime: any Runtime) throws {
        let extensions = try _activeExtensions(runtime: runtime).get()
        guard additionalSigned.count == extensions.count else {
            throw ExtrinsicCodingError.badExtrasCount(expected: extensions.count,
                                                      got: additionalSigned.count)
        }
        for (addSigned, ext) in zip(additionalSigned, extensions) {
            try runtime.encode(value: addSigned, in: &encoder, as: ext.addId)
        }
    }
    
    public func extra<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws -> TExtra {
        try runtime.decode(from: &decoder, id: runtime.types.extrinsicExtra.id)
    }
    
    public func additionalSigned<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> TAdditionalSigned {
        try _activeExtensions(runtime: runtime).get().map { ext in
            try runtime.decode(from: &decoder, id: ext.addId)
        }
    }
    
    public func validate(
        runtime: any Runtime
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeError>> {
        _activeExtensions(runtime: runtime)
            .mapError {.left($0)}
            .flatMap { exts in
                exts.voidErrorMap { ext in
                    ext.ext.validate(
                        config: BC.self, runtime: runtime,
                        extra: ext.extId, additionalSigned: ext.addId
                    )
                }.mapError {.right($0)}
            }
    }
    
    private func _activeExtensions(
        runtime: any Runtime
    ) -> Result<[(ext: any DynamicExtrinsicExtension, extId: NetworkType.Id, addId: NetworkType.Id)],
                ExtrinsicCodingError>
    {
        guard runtime.metadata.extrinsic.version == version else {
            return .failure(.badExtrinsicVersion(
                supported: version,
                got: runtime.metadata.extrinsic.version
            ))
        }
        return runtime.metadata.extrinsic.extensions.resultMap { info in
            let id = ExtrinsicExtensionId(info.identifier)
            guard let ext = self.extensions[id] else {
                return .failure(.unknownExtension(identifier: id))
            }
            return .success((ext, info.type.id, info.additionalSigned.id))
        }
    }
}
