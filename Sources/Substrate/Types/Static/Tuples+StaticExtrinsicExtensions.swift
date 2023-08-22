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
    TConfig == T1.TConfig, TExtra: SomeTuple1, TExtra.T1 == T1.TExtra,
    TAdditionalSigned: SomeTuple1, TAdditionalSigned.T1 == T1.TAdditionalSigned
{
    @inlinable
    var identifiers: [ExtrinsicExtensionId] { [first.identifier] }
    
    @inlinable
    func params<R: RootApi>(
        api: R, partial params: SBT<TConfig>.SigningParamsPartial
    ) async throws -> SBT<TConfig>.SigningParamsPartial where SBC<R.RC> == TConfig {
        try await first.params(api: api, partial: params)
    }
    
    @inlinable
    init() { self.init(T1()) }
    
    @inlinable
    func extra<R: RootApi>(
        api: R, params: SBT<TConfig>.SigningParams
    ) async throws -> TExtra where SBC<R.RC> == TConfig {
        try await TExtra(first.extra(api: api, params: params))
    }
    
    @inlinable
    func additionalSigned<R: RootApi>(
        api: R, params: SBT<TConfig>.SigningParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig {
        try await TAdditionalSigned(first.additionalSigned(api: api, params: params))
    }
    
    @inlinable
    func validate(
        runtime: any Runtime,
        types: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeValidationError>> {
        guard let info = types[first.identifier] else {
            return .failure(.left(.unknownExtension(identifier: first.identifier)))
        }
        return first.validate(runtime: runtime, extra: info.extId,
                              additionalSigned: info.addId).mapError{.right($0)}
    }
}

public extension ListTuple where
    Self: StaticExtrinsicExtensions, DroppedLast: StaticExtrinsicExtensions,
    Last: StaticExtrinsicExtension, TExtra: ListTuple, TAdditionalSigned: ListTuple,
    DroppedLast.TConfig == TConfig, Last.TConfig == TConfig,
    TExtra.DroppedLast == DroppedLast.TExtra, TExtra.Last == Last.TExtra,
    TAdditionalSigned.DroppedLast == DroppedLast.TAdditionalSigned,
    TAdditionalSigned.Last == Last.TAdditionalSigned
{
    @inlinable
    var identifiers: [ExtrinsicExtensionId] { dropLast.identifiers + [last.identifier] }

    @inlinable
    init() { self.init(first: DroppedLast(), last: Last()) }
    
    @inlinable
    func params<R: RootApi>(
        api: R, partial params: SBT<TConfig>.SigningParamsPartial
    ) async throws -> SBT<TConfig>.SigningParamsPartial where SBC<R.RC> == TConfig {
        let prefix = try await dropLast.params(api: api, partial: params)
        return try await last.params(api: api, partial: prefix)
    }

    @inlinable
    func extra<R: RootApi>(
        api: R, params: SBT<TConfig>.SigningParams
    ) async throws -> TExtra where SBC<R.RC> == TConfig {
        try await TExtra(first: dropLast.extra(api: api, params: params),
                         last: last.extra(api: api, params: params))
    }

    @inlinable
    func additionalSigned<R: RootApi>(
        api: R, params: SBT<TConfig>.SigningParams
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig {
        try await TAdditionalSigned(first: dropLast.additionalSigned(api: api, params: params),
                                    last: last.additionalSigned(api: api, params: params))
    }

    @inlinable
    func validate(
        runtime: any Runtime,
        types: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeValidationError>> {
        guard let info = types[last.identifier] else {
            return .failure(.left(.unknownExtension(identifier: last.identifier)))
        }
        return last.validate(runtime: runtime, extra: info.extId, additionalSigned: info.addId)
            .mapError{.right($0)}
            .flatMap{dropLast.validate(runtime: runtime, types: types)}
    }
}

extension Tuple1: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
    where T1: StaticExtrinsicExtension
{
    public typealias TConfig = T1.TConfig
    public typealias TExtra = Tuple1<T1.TExtra>
    public typealias TAdditionalSigned = Tuple1<T1.TAdditionalSigned>
}

extension Tuple2: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig
{
    public typealias TConfig = T1.TConfig
    public typealias TAdditionalSigned = Tuple2<T1.TAdditionalSigned, T2.TAdditionalSigned>
    public typealias TExtra = Tuple2<T1.TExtra, T2.TExtra>
}

extension Tuple3: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig
{
    public typealias TConfig = T1.TConfig
    public typealias TAdditionalSigned =
        Tuple3<T1.TAdditionalSigned, T2.TAdditionalSigned, T3.TAdditionalSigned>
    public typealias TExtra = Tuple3<T1.TExtra, T2.TExtra, T3.TExtra>
}

extension Tuple4: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig
{
    public typealias TConfig = T1.TConfig
    public typealias TAdditionalSigned = Tuple4<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned>
    public typealias TExtra = Tuple4<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra>
}

extension Tuple5: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig
{
    public typealias TConfig = T1.TConfig
    public typealias TAdditionalSigned = Tuple5<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned>
    public typealias TExtra = Tuple5<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra>
}

extension Tuple6: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig
{
    public typealias TConfig = T1.TConfig
    public typealias TAdditionalSigned = Tuple6<T1.TAdditionalSigned, T2.TAdditionalSigned,
                                                T3.TAdditionalSigned, T4.TAdditionalSigned,
                                                T5.TAdditionalSigned, T6.TAdditionalSigned>
    public typealias TExtra = Tuple6<T1.TExtra, T2.TExtra, T3.TExtra, T4.TExtra, T5.TExtra,
                                     T6.TExtra>
}

extension Tuple7: StaticExtrinsicExtensions, StaticExtrinsicExtensionBase
where
    DroppedLast: StaticExtrinsicExtensions, Last: StaticExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig, T12.TConfig == T13.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig, T12.TConfig == T13.TConfig,
    T13.TConfig == T14.TConfig
{
    public typealias TConfig = T1.TConfig
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
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig, T12.TConfig == T13.TConfig,
    T13.TConfig == T14.TConfig, T14.TConfig == T15.TConfig
{
    public typealias TConfig = T1.TConfig
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
