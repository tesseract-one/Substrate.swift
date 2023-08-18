//
//  Tuples+StaticExtrinsicExtensions.swift
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

public extension ListTuple where
    Self: StaticExtrinsicExtensions, DroppedLast: StaticExtrinsicExtensions,
    Last: StaticExtrinsicExtension, TExtra: ListTuple, TAdditionalSigned: ListTuple,
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

extension Tuple4: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple4<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned>
    public typealias TExtra = Tuple4<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra>
}

extension Tuple5: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple5<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned>
    public typealias TExtra = Tuple5<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra>
}

extension Tuple6: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple6<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned, T6.TAdditionalSigned>
    public typealias TExtra = Tuple6<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                     T6.TExtra>
}

extension Tuple7: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple7<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                T7.TAdditionalSigned>
    public typealias TExtra = Tuple7<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                     T6.TExtra, T7.TExtra>
}

extension Tuple8: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple8<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                T7.TAdditionalSigned, T8.TAdditionalSigned>
    public typealias TExtra = Tuple8<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                     T6.TExtra, T7.TExtra, T8.TExtra>
}

extension Tuple9: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple9<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                T9.TAdditionalSigned>
    public typealias TExtra = Tuple9<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                     T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra>
}

extension Tuple10: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams,
    T9.TConfig == T10.TConfig, T9.TParams == T10.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple10<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                 T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                 T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                 T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                 T9.TAdditionalSigned, T10.TAdditionalSigned>
    public typealias TExtra = Tuple10<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                      T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra, T10.TExtra>
}

extension Tuple11: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams,
    T9.TConfig == T10.TConfig, T9.TParams == T10.TParams,
    T10.TConfig == T11.TConfig, T10.TParams == T11.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple11<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                 T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                 T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                 T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                 T9.TAdditionalSigned, T10.TAdditionalSigned,
                                                 T11.TAdditionalSigned>
    public typealias TExtra = Tuple11<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                      T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra, T10.TExtra,
                                      T11.TExtra>
}

extension Tuple12: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams,
    T9.TConfig == T10.TConfig, T9.TParams == T10.TParams,
    T10.TConfig == T11.TConfig, T10.TParams == T11.TParams,
    T11.TConfig == T12.TConfig, T11.TParams == T12.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple12<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                 T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                 T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                 T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                 T9.TAdditionalSigned, T10.TAdditionalSigned,
                                                 T11.TAdditionalSigned, T12.TAdditionalSigned>
    public typealias TExtra = Tuple12<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                      T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra, T10.TExtra,
                                      T11.TExtra, T12.TExtra>
}

extension Tuple13: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams,
    T9.TConfig == T10.TConfig, T9.TParams == T10.TParams,
    T10.TConfig == T11.TConfig, T10.TParams == T11.TParams,
    T11.TConfig == T12.TConfig, T11.TParams == T12.TParams,
    T12.TConfig == T13.TConfig, T12.TParams == T13.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple13<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                 T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                 T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                 T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                 T9.TAdditionalSigned, T10.TAdditionalSigned,
                                                 T11.TAdditionalSigned, T12.TAdditionalSigned,
                                                 T13.TAdditionalSigned>
    public typealias TExtra = Tuple13<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                      T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra, T10.TExtra,
                                      T11.TExtra, T12.TExtra, T13.TExtra>
}

extension Tuple14: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams,
    T9.TConfig == T10.TConfig, T9.TParams == T10.TParams,
    T10.TConfig == T11.TConfig, T10.TParams == T11.TParams,
    T11.TConfig == T12.TConfig, T11.TParams == T12.TParams,
    T12.TConfig == T13.TConfig, T12.TParams == T13.TParams,
    T13.TConfig == T14.TConfig, T13.TParams == T14.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple14<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                 T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                 T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                 T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                 T9.TAdditionalSigned, T10.TAdditionalSigned,
                                                 T11.TAdditionalSigned, T12.TAdditionalSigned,
                                                 T13.TAdditionalSigned, T14.TAdditionalSigned>
    public typealias TExtra = Tuple14<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                      T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra, T10.TExtra,
                                      T11.TExtra, T12.TExtra, T13.TExtra, T14.TExtra>
}

extension Tuple15: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T1.TParams == T2.TParams,
    T2.TConfig == T3.TConfig, T2.TParams == T3.TParams,
    T3.TConfig == T4.TConfig, T3.TParams == T4.TParams,
    T4.TConfig == T5.TConfig, T4.TParams == T5.TParams,
    T5.TConfig == T6.TConfig, T5.TParams == T6.TParams,
    T6.TConfig == T7.TConfig, T6.TParams == T7.TParams,
    T7.TConfig == T8.TConfig, T7.TParams == T8.TParams,
    T8.TConfig == T9.TConfig, T8.TParams == T9.TParams,
    T9.TConfig == T10.TConfig, T9.TParams == T10.TParams,
    T10.TConfig == T11.TConfig, T10.TParams == T11.TParams,
    T11.TConfig == T12.TConfig, T11.TParams == T12.TParams,
    T12.TConfig == T13.TConfig, T12.TParams == T13.TParams,
    T13.TConfig == T14.TConfig, T13.TParams == T14.TParams,
    T14.TConfig == T15.TConfig, T14.TParams == T15.TParams
{
    public typealias TConfig = T1.TConfig
    public typealias TParams = T1.TParams
    public typealias TAdditionalSigned = Tuple15<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                 T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                 T5.TAdditionalSigned, T6.TAdditionalSigned,
                                                 T7.TAdditionalSigned, T8.TAdditionalSigned,
                                                 T9.TAdditionalSigned, T10.TAdditionalSigned,
                                                 T11.TAdditionalSigned, T12.TAdditionalSigned,
                                                 T13.TAdditionalSigned, T14.TAdditionalSigned,
                                                 T15.TAdditionalSigned>
    public typealias TExtra = Tuple15<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                      T6.TExtra, T7.TExtra, T8.TExtra, T9.TExtra, T10.TExtra,
                                      T11.TExtra, T12.TExtra, T13.TExtra, T14.TExtra, T15.TExtra>
}
