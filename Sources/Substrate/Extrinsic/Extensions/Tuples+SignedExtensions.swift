//
//  Tuples+SignedExtensions.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import Tuples

public extension SomeTuple1 where
    Self: StaticExtrinsicExtension, T1: StaticExtrinsicExtension,
    TConfig == T1.TConfig, TParams == T1.TParams,
    TExtra: SomeTuple1, TExtra.T1 == T1.TExtra,
    TAdditionalSigned: SomeTuple1, TAdditionalSigned.T1 == T1.TAdditionalSigned
{
    var identifier: [ExtrinsicExtensionId] { first.identifier }
    
    func extra<R>(api: R, params: TParams) async throws -> TExtra
        where R: RootApi, TConfig == R.RC
    {
        try await TExtra(first.extra(api: api, params: params))
    }
    
    func additionalSigned<R>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R: RootApi, TConfig == R.RC
    {
        try await TAdditionalSigned(first.additionalSigned(api: api, params: params))
    }
}

public extension LinkedTuple where
    Self: StaticExtrinsicExtension, DroppedLast: StaticExtrinsicExtension,
    Last: StaticExtrinsicExtension, TExtra: LinkedTuple, TAdditionalSigned: LinkedTuple,
    DroppedLast.TParams == TParams, Last.TParams == TParams,
    DroppedLast.TConfig == TConfig, Last.TConfig == TConfig,
    TExtra.DroppedLast == DroppedLast.TExtra, TExtra.Last == Last.TExtra,
    TAdditionalSigned.DroppedLast == DroppedLast.TAdditionalSigned,
    TAdditionalSigned.Last == Last.TAdditionalSigned
{
    var identifier: [ExtrinsicExtensionId] { dropLast.identifier + last.identifier }
    
    func extra<R>(api: R, params: TParams) async throws -> TExtra
        where R: RootApi, TConfig == R.RC
    {
        try await TExtra(first: dropLast.extra(api: api, params: params),
                         last: last.extra(api: api, params: params))
    }
    
    func additionalSigned<R>(api: R, params: TParams) async throws -> TAdditionalSigned
        where R: RootApi, TConfig == R.RC
    {
        try await TAdditionalSigned(first: dropLast.additionalSigned(api: api, params: params),
                                    last: last.additionalSigned(api: api, params: params))
    }
}

extension Tuple1: StaticExtrinsicExtension where T1: StaticExtrinsicExtension {
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TExtra = Tuple1<T1.TExtra>
    public typealias TAdditionalSigned = Tuple1<T1.TAdditionalSigned>
}

extension Tuple2: StaticExtrinsicExtension where
    DroppedLast: StaticExtrinsicExtension, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple2<T1.TAdditionalSigned, T2.TAdditionalSigned>
    public typealias TExtra = Tuple2<T1.TExtra, T2.TExtra>
}
