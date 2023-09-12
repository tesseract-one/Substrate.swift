//
//  RpcApi+Client.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
import ContextCodable
import Substrate

extension RpcApiRegistry: RpcCallableClient where R.CL: RpcCallableClient {
    @inlinable
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await _rootApi.client.call(method: method, params: params)
    }
    
    @inlinable
    public func call<Params: ContextEncodable, Res: Decodable>(
        method: String, params: Params, context: Params.EncodingContext
    ) async throws -> Res {
        try await _rootApi.client.call(method: method, params: params, context: context)
    }
    
    @inlinable
    public func call<Params: Encodable, Res: ContextDecodable>(
        method: String, params: Params, context: Res.DecodingContext
    ) async throws -> Res {
        try await _rootApi.client.call(method: method, params: params, context: context)
    }
    
    @inlinable
    public func call<Params: ContextEncodable, Res: ContextDecodable>(
        method: String, params: Params,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Res.DecodingContext
    ) async throws -> Res {
        try await _rootApi.client.call(method: method, params: params,
                                       encoding: econtext, decoding: dcontext)
    }
}

extension RpcApiRegistry: RpcSubscribableClient where R.CL: RpcSubscribableClient {
    @inlinable
    public func subscribe<P: Encodable, E: Decodable>(
        method: String, params: P, unsubscribe umethod: String
    ) async throws -> AsyncThrowingStream<E, Error> {
        try await _rootApi.client.subscribe(method: method, params: params, unsubscribe: umethod)
    }
    
    @inlinable
    public func subscribe<Params: ContextEncodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String, context: Params.EncodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await _rootApi.client.subscribe(method: method, params: params,
                                            unsubscribe: umethod, context: context)
    }
    
    @inlinable
    public func subscribe<Params: Encodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String, context: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await _rootApi.client.subscribe(method: method, params: params,
                                            unsubscribe: umethod, context: context)
    }
    
    @inlinable
    public func subscribe<Params: ContextEncodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await _rootApi.client.subscribe(method: method, params: params, unsubscribe: umethod,
                                            encoding: econtext, decoding: dcontext)
    }
}

public extension RpcApiRegistry where R.CL: RpcCallableClient {
    func methods() async throws -> Set<String> {
        try await RpcClient<R.RC, R.CL>.rpcMethods(client: _rootApi.client)
    }
}
