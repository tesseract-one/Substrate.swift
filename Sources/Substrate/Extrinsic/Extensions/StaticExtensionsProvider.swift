//
//  StaticSignedExtensions.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import Tuples
import ScaleCodec

public protocol StaticExtrinsicExtensionBase<TConfig, TParams> {
    associatedtype TConfig: Config
    associatedtype TParams: ExtraSigningParameters
    associatedtype TExtra: RuntimeCodable
    associatedtype TAdditionalSigned: RuntimeCodable
    
    func params<R: RootApi<TConfig>>(api: R, partial params: TParams.TPartial) async throws -> TParams.TPartial
    func extra<R: RootApi<TConfig>>(api: R, params: TParams) async throws -> TExtra
    func additionalSigned<R: RootApi<TConfig>>(api: R, params: TParams) async throws -> TAdditionalSigned
}

public protocol StaticExtrinsicExtension<TConfig, TParams>: StaticExtrinsicExtensionBase {
    var identifier: ExtrinsicExtensionId { get }
}

public protocol StaticExtrinsicExtensions<TConfig, TParams>: StaticExtrinsicExtensionBase {
    var identifiers: [ExtrinsicExtensionId] { get }
}

public class StaticSignedExtensionsProvider<Ext: StaticExtrinsicExtensions>: SignedExtensionsProvider {
    public typealias RC = Ext.TConfig    
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
    
    public func params(partial params: TSigningParams.TPartial) async throws -> TSigningParams {
        try await TSigningParams(partial: _params(params))
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
        let extNames = extensions.identifiers.map { $0.rawValue }
        guard extNames == metaExtNames else {
            throw ExtrinsicCodingError.badExtras(expected: metaExtNames, got: extensions.identifiers)
        }
        self._runtime = api.runtime
        let ext = self.extensions
        self._params = { [unowned api] params in
            try await ext.params(api: api, partial: params)
        }
        self._extra = { [unowned api] params in
            try await ext.extra(api: api, params: params)
        }
        self._addSigned = { [unowned api] params in
            try await ext.additionalSigned(api: api, params: params)
        }
    }
}
