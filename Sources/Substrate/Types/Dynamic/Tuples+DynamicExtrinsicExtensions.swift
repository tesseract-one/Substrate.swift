//
//  Tuples+DynamicExtrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation
import Tuples

public extension SomeTuple1 where
    Self: DynamicExtrinsicExtensions, T1: DynamicExtrinsicExtension, TConfig == T1.TConfig
{
    var identifiers: [ExtrinsicExtensionId] { [first.identifier] }
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: AnySigningParams<TConfig>.TPartial,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> AnySigningParams<TConfig>.TPartial {
        guard extensions[first.identifier] != nil else {
            return params
        }
        return try await first.params(api: api, partial: params)
    }
    
    func extra<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> [ExtrinsicExtensionId: Value<RuntimeType.Id>] {
        guard let extId = extensions[first.identifier]?.extId else {
            return [:]
        }
        return try await [first.identifier: first.extra(api: api, params: params, id: extId)]
    }
    
    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> [ExtrinsicExtensionId: Value<RuntimeType.Id>] {
        guard let addId = extensions[first.identifier]?.addId else {
            return [:]
        }
        return try await [first.identifier: first.additionalSigned(api: api, params: params, id: addId)]
    }
}

public extension ListTuple where Self: DynamicExtrinsicExtensions,
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    DroppedLast.TConfig == TConfig, Last.TConfig == TConfig
{
    var identifiers: [ExtrinsicExtensionId] { dropLast.identifiers + [last.identifier] }
    
    func params<R: RootApi<TConfig>>(
        api: R, partial params: AnySigningParams<TConfig>.TPartial,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> AnySigningParams<TConfig>.TPartial {
        let partial = try await dropLast.params(api: api, partial: params, extensions: extensions)
        guard extensions[last.identifier] != nil else {
            return partial
        }
        return try await last.params(api: api, partial: partial)
    }
    
    func extra<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> [ExtrinsicExtensionId: Value<RuntimeType.Id>] {
        var extra = try await dropLast.extra(api: api, params: params, extensions: extensions)
        if let extId = extensions[last.identifier]?.extId {
            extra[last.identifier] = try await last.extra(api: api, params: params, id: extId)
        }
        return extra
    }
    
    func additionalSigned<R: RootApi<TConfig>>(
        api: R, params: AnySigningParams<TConfig>,
        extensions: [ExtrinsicExtensionId: (extId: RuntimeType.Id, addId: RuntimeType.Id)]
    ) async throws -> [ExtrinsicExtensionId: Value<RuntimeType.Id>] {
        var addSigned = try await dropLast.additionalSigned(api: api, params: params, extensions: extensions)
        if let addId = extensions[last.identifier]?.addId {
            addSigned[last.identifier] = try await last.additionalSigned(api: api, params: params, id: addId)
        }
        return addSigned
    }
}

extension Tuple1: DynamicExtrinsicExtensions where T1: DynamicExtrinsicExtension {
    public typealias TConfig = T1.TConfig
}

extension Tuple2: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple3: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple4: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple5: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple6: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple7: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple8: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple9: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple10: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple11: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple12: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple13: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig, T12.TConfig == T13.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple14: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig, T12.TConfig == T13.TConfig,
    T13.TConfig == T14.TConfig
{
    public typealias TConfig = T1.TConfig
}

extension Tuple15: DynamicExtrinsicExtensions where
    DroppedLast: DynamicExtrinsicExtensions, Last: DynamicExtrinsicExtension,
    T1.TConfig == T2.TConfig, T2.TConfig == T3.TConfig, T3.TConfig == T4.TConfig,
    T4.TConfig == T5.TConfig, T5.TConfig == T6.TConfig, T6.TConfig == T7.TConfig,
    T7.TConfig == T8.TConfig, T8.TConfig == T9.TConfig, T9.TConfig == T10.TConfig,
    T10.TConfig == T11.TConfig, T11.TConfig == T12.TConfig, T12.TConfig == T13.TConfig,
    T13.TConfig == T14.TConfig, T14.TConfig == T15.TConfig
{
    public typealias TConfig = T1.TConfig
}
