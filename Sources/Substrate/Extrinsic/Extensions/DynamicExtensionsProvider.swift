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
        api: R, params: AnySigningParams<SBC<R.RC>>, type: TypeDefinition
    ) async throws -> Value<TypeDefinition>

    func additionalSigned<R: RootApi>(
        api: R, params: AnySigningParams<SBC<R.RC>>, type: TypeDefinition
    ) async throws -> Value<TypeDefinition>
    
    func validate<C: BasicConfig>(
        config: C.Type, runtime: any Runtime,
        extra: TypeDefinition, additionalSigned: TypeDefinition
    ) -> Result<Void, TypeError>
}

public class DynamicSignedExtensionsProvider<BC: BasicConfig>: SignedExtensionsProvider {
    public typealias TConfig = BC
    public typealias TParams = AnySigningParams<BC>
    public typealias TExtra = Value<TypeDefinition>
    public typealias TAdditionalSigned = [Value<TypeDefinition>]
    
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
        var extra: [Value<TypeDefinition>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.ext.extra(api: api, params: params, type: ext.extId))
        }
        return Value(value: .sequence(extra), context: api.runtime.types.extrinsicExtra)
    }
    
    public func additionalSigned<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig {
        let extensions = try _activeExtensions(runtime: api.runtime).get()
        var additional: [Value<TypeDefinition>] = []
        additional.reserveCapacity(extensions.count)
        for ext in extensions {
            try await additional.append(ext.ext.additionalSigned(api: api, params: params, type: ext.addId))
        }
        return additional
    }
    
    public func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E,
                                              runtime: any Runtime) throws {
        try runtime.encode(value: extra, in: &encoder,
                           as: runtime.types.extrinsicExtra)
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
        try runtime.decode(from: &decoder, type: runtime.types.extrinsicExtra)
    }
    
    public func additionalSigned<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> TAdditionalSigned {
        try _activeExtensions(runtime: runtime).get().map { ext in
            try runtime.decode(from: &decoder, type: ext.addId)
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
    ) -> Result<[(ext: any DynamicExtrinsicExtension, extId: TypeDefinition, addId: TypeDefinition)],
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
            return .success((ext, info.type, info.additionalSigned))
        }
    }
}
