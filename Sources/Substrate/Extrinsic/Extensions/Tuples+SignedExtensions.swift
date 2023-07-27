//
//  Tuples+SignedExtensions.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import Tuples

public extension SomeTuple1 where
    Self: StaticExtrinsicExtensions, T1: StaticExtrinsicExtension,
    TConfig == T1.TConfig, TParams == T1.TParams,
    TExtra: SomeTuple1, TExtra.T1 == T1.TExtra,
    TAdditionalSigned: SomeTuple1, TAdditionalSigned.T1 == T1.TAdditionalSigned
{
    var identifiers: [ExtrinsicExtensionId] { [first.identifier] }
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        try await first.params(api: api, partial: params)
    }
    
    func extra<R: RootApi<TConfig>>(api: R, params: TParams) async throws -> TExtra {
        try await TExtra(first.extra(api: api, params: params))
    }
    
    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        try await TAdditionalSigned(first.additionalSigned(api: api, params: params))
    }
}

public extension LinkedTuple where
    Self: StaticExtrinsicExtensions, DroppedLast: StaticExtrinsicExtensions,
    Last: StaticExtrinsicExtension, TExtra: LinkedTuple, TAdditionalSigned: LinkedTuple,
    DroppedLast.TParams == TParams, Last.TParams == TParams,
    DroppedLast.TConfig == TConfig, Last.TConfig == TConfig,
    TExtra.DroppedLast == DroppedLast.TExtra, TExtra.Last == Last.TExtra,
    TAdditionalSigned.DroppedLast == DroppedLast.TAdditionalSigned,
    TAdditionalSigned.Last == Last.TAdditionalSigned
{
    var identifiers: [ExtrinsicExtensionId] { dropLast.identifiers + [last.identifier] }
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: TParams.TPartial
    ) async throws -> TParams.TPartial {
        let prefix = try await dropLast.params(api: api, partial: params)
        return try await last.params(api: api, partial: prefix)
    }
    
    func extra<R: RootApi<TConfig>>(api: R, params: TParams) async throws -> TExtra {
        try await TExtra(first: dropLast.extra(api: api, params: params),
                         last: last.extra(api: api, params: params))
    }
    
    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: TParams
    ) async throws -> TAdditionalSigned {
        try await TAdditionalSigned(first: dropLast.additionalSigned(api: api, params: params),
                                    last: last.additionalSigned(api: api, params: params))
    }
}

extension Tuple1: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
    where T1: StaticExtrinsicExtension
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TExtra = Tuple1<T1.TExtra>
    public typealias TAdditionalSigned = Tuple1<T1.TAdditionalSigned>
}

extension Tuple2: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple2<T1.TAdditionalSigned, T2.TAdditionalSigned>
    public typealias TExtra = Tuple2<T1.TExtra, T2.TExtra>
}

extension Tuple3: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned =
        Tuple3<T1.TAdditionalSigned, T2.TAdditionalSigned, T3.TAdditionalSigned>
    public typealias TExtra = Tuple3<T1.TExtra, T2.TExtra, T3.TExtra>
}
