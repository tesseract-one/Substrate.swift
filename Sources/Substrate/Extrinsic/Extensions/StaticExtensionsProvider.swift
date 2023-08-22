//
//  StaticSignedExtensions.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import Tuples
import ScaleCodec

public protocol StaticExtrinsicExtensionBase {
    associatedtype TConfig: Config
    associatedtype TExtra
    associatedtype TAdditionalSigned
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: TConfig.TSigningParams.TPartial
    ) async throws -> TConfig.TSigningParams.TPartial
    func extra<R: RootApi<TConfig>>(api: R, params: TConfig.TSigningParams) async throws -> TExtra
    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: TConfig.TSigningParams
    ) async throws -> TAdditionalSigned
}

public protocol StaticExtrinsicExtension: StaticExtrinsicExtensionBase, ExtrinsicSignedExtension
    where TExtra: RuntimeCodable, TAdditionalSigned: RuntimeCodable
{
    static var identifier: ExtrinsicExtensionId { get }
    
    func validate(
        runtime: any Runtime,
        extra: RuntimeType.Id,
        additionalSigned: RuntimeType.Id
    ) -> Result<Void, TypeValidationError>
}

public extension StaticExtrinsicExtension {
    var identifier: ExtrinsicExtensionId { Self.identifier }
}

public extension StaticExtrinsicExtension where
    TExtra: ValidatableRuntimeType, TAdditionalSigned: ValidatableRuntimeType
{
    func validate(runtime: Runtime, extra: RuntimeType.Id,
                  additionalSigned: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        TExtra.validate(runtime: runtime, type: extra).flatMap {
            TAdditionalSigned.validate(runtime: runtime, type: additionalSigned)
        }
    }
}

public protocol StaticExtrinsicExtensions: StaticExtrinsicExtensionBase
    where TExtra: RuntimeCodable, TAdditionalSigned: RuntimeCodable
{
    var identifiers: [ExtrinsicExtensionId] { get }
    
    func validate(
        runtime: any Runtime,
        types: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeValidationError>>
}

public class StaticSignedExtensionsProvider<Ext: StaticExtrinsicExtensions>: SignedExtensionsProvider {
    public typealias TConfig = Ext.TConfig
    public typealias TExtra = Ext.TExtra
    public typealias TAdditionalSigned = Ext.TAdditionalSigned
    
    public let extensions: Ext
    public let version: UInt8
    
    public init(extensions: Ext, version: UInt8) {
        self.extensions = extensions
        self.version = version
    }
    
    public func params<R: RootApi<TConfig>>(partial params: TConfig.TSigningParams.TPartial,
                                            for api: R) async throws -> TConfig.TSigningParams
    {
        try await TConfig.TSigningParams(partial: extensions.params(api: api, partial: params))
    }
    
    public func extra<R: RootApi<TConfig>>(params: TConfig.TSigningParams,
                                           for api: R) async throws -> TExtra
    {
        try await extensions.extra(api: api, params: params)
    }
    
    public func additionalSigned<R: RootApi<TConfig>>(params: TConfig.TSigningParams,
                                                      for api: R) async throws -> TAdditionalSigned
    {
        try await extensions.additionalSigned(api: api, params: params)
    }
    
    public func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E,
                                              runtime: any Runtime) throws
    {
        try runtime.encode(value: extra, in: &encoder)
    }
    
    public func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned,
                                              in encoder: inout E,
                                              runtime: any Runtime) throws
    {
        try runtime.encode(value: additionalSigned, in: &encoder)
    }
    
    public func extra<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws -> TExtra {
        try runtime.decode(from: &decoder)
    }
    
    public func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D,
                                                        runtime: any Runtime) throws -> TAdditionalSigned {
        try runtime.decode(from: &decoder)
    }
    
    public func validate(
        runtime: any Runtime
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeValidationError>> {
        guard runtime.metadata.extrinsic.version == version else {
            return .failure(.left(.badExtrinsicVersion(
                supported: version,
                got: runtime.metadata.extrinsic.version
            )))
        }
        let ext = runtime.metadata.extrinsic.extensions.map { info in
            (key: ExtrinsicExtensionId(info.identifier),
             value: (extId: info.type.id, addId: info.additionalSigned.id))
        }
        let unknown = Set(ext.map{$0.key}).subtracting(extensions.identifiers)
        guard unknown.count == 0 else {
            return .failure(.left(.unknownExtension(identifier: unknown.first!)))
        }
        return extensions.validate(runtime: runtime, types: Dictionary(uniqueKeysWithValues: ext))
    }
}
