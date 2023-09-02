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
    associatedtype TConfig: BasicConfig
    associatedtype TParams: ExtraSigningParameters
    associatedtype TExtra
    associatedtype TAdditionalSigned
    
    init()
    
    func params<R: RootApi>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial where SBC<R.RC> == TConfig
    
    func extra<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TExtra where SBC<R.RC> == TConfig
    
    func additionalSigned<R: RootApi>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig
}

public protocol StaticExtrinsicExtension: StaticExtrinsicExtensionBase, ExtrinsicSignedExtension
    where TExtra: RuntimeCodable, TAdditionalSigned: RuntimeCodable
{
    static var identifier: ExtrinsicExtensionId { get }
    
    func validate(
        runtime: any Runtime,
        extra: NetworkType.Id,
        additionalSigned: NetworkType.Id
    ) -> Result<Void, DynamicValidationError>
}

public extension StaticExtrinsicExtension {
    var identifier: ExtrinsicExtensionId { Self.identifier }
}

public extension StaticExtrinsicExtension where
    TExtra: RuntimeDynamicValidatable, TAdditionalSigned: RuntimeDynamicValidatable
{
    func validate(runtime: Runtime, extra: NetworkType.Id,
                  additionalSigned: NetworkType.Id) -> Result<Void, DynamicValidationError>
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
        types: [ExtrinsicExtensionId: (extId: NetworkType.Id, addId: NetworkType.Id)]
    ) -> Result<Void, Either<ExtrinsicCodingError, DynamicValidationError>>
}

public class StaticSignedExtensionsProvider<Ext: StaticExtrinsicExtensions>: SignedExtensionsProvider {
    public typealias TConfig = Ext.TConfig
    public typealias TParams = Ext.TParams
    public typealias TExtra = Ext.TExtra
    public typealias TAdditionalSigned = Ext.TAdditionalSigned
    
    public let extensions: Ext
    public let version: UInt8
    
    public init(extensions: Ext, version: UInt8) {
        self.extensions = extensions
        self.version = version
    }
    
    public func params<R: RootApi>(
        partial params: TParams.TPartial, for api: R
    ) async throws -> TParams where SBC<R.RC> == TConfig {
        try await TParams(partial: extensions.params(api: api, partial: params))
    }
    
    public func extra<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TExtra where SBC<R.RC> == TConfig {
        try await extensions.extra(api: api, params: params)
    }
    
    public func additionalSigned<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig {
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
    ) -> Result<Void, Either<ExtrinsicCodingError, DynamicValidationError>> {
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
