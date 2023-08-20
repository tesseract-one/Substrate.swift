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
    associatedtype TParams: ExtraSigningParameters
    associatedtype TExtra
    associatedtype TAdditionalSigned
    
    func params<R: RootApi<TConfig>>(api: R,
                                     partial params: TParams.TPartial) async throws -> TParams.TPartial
    func extra<R: RootApi<TConfig>>(api: R, params: TParams) async throws -> TExtra
    func additionalSigned<R: RootApi<TConfig>>(api: R,
                                      params: TParams) async throws -> TAdditionalSigned
}

public protocol StaticExtrinsicExtension: StaticExtrinsicExtensionBase, ExtrinsicSignedExtension
    where TExtra: RuntimeCodable, TAdditionalSigned: RuntimeCodable
{
    static var identifier: ExtrinsicExtensionId { get }
}

public extension StaticExtrinsicExtension {
    var identifier: ExtrinsicExtensionId { Self.identifier }
}

public protocol StaticExtrinsicExtensions<TParams>: StaticExtrinsicExtensionBase
    where TExtra: RuntimeCodable, TAdditionalSigned: RuntimeCodable
{
    var identifiers: [ExtrinsicExtensionId] { get }
}

public class StaticSignedExtensionsProvider<Ext: StaticExtrinsicExtensions>: SignedExtensionsProvider {
    public typealias TConfig = Ext.TConfig
    public typealias TExtra = Ext.TExtra
    public typealias TAdditionalSigned = Ext.TAdditionalSigned
    public typealias TSigningParams = Ext.TParams
    
    public let extensions: Ext
    public let version: UInt8
    
    private var _params: ((TSigningParams.TPartial) async throws -> TSigningParams.TPartial)!
    private var _extra: ((TSigningParams) async throws -> TExtra)!
    private var _addSigned: ((TSigningParams) async throws -> TAdditionalSigned)!
    private weak var _runtime: (any Runtime)!
    
    public init(extensions: Ext, version: UInt8) {
        self.extensions = extensions
        self.version = version
    }
    
    public func params<R: RootApi<TConfig>>(partial params: TSigningParams.TPartial,
                                            for api: R) async throws -> TSigningParams
    {
        try await TSigningParams(partial: extensions.params(api: api, partial: params))
    }
    
    public func extra<R: RootApi<TConfig>>(params: TSigningParams,
                                           for api: R) async throws -> TExtra
    {
        try await extensions.extra(api: api, params: params)
    }
    
    public func additionalSigned<R: RootApi<TConfig>>(params: TSigningParams,
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
}
