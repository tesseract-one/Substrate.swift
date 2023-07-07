//
//  RpcClientDefs.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ContextCodable

public protocol RpcCallableClient {
    func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res
    
    func call<Params: ContextEncodable, Res: Decodable>(
        method: String, params: Params, context: Params.EncodingContext
    ) async throws -> Res
    
    func call<Params: Encodable, Res: ContextDecodable>(
        method: String, params: Params, context: Res.DecodingContext
    ) async throws -> Res
    
    func call<Params: ContextEncodable, Res: ContextDecodable>(
        method: String, params: Params,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Res.DecodingContext
    ) async throws -> Res
}

public protocol RpcSubscribableClient: RpcCallableClient {
    func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String
    ) async throws -> AsyncThrowingStream<Event, Error>
    
    func subscribe<Params: ContextEncodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String, context: Params.EncodingContext
    ) async throws -> AsyncThrowingStream<Event, Error>
    
    func subscribe<Params: Encodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String, context: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error>
    
    func subscribe<Params: ContextEncodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error>
}

public extension RpcCallableClient {
    @inlinable
    func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params, _: Res.Type
    ) async throws -> Res {
        try await call(method: method, params: params)
    }
    
    @inlinable
    func call<Params: ContextEncodable, Res: Decodable>(
        method: String, params: Params, context: Params.EncodingContext, _: Res.Type
    ) async throws -> Res {
        try await call(method: method, params: params, context: context)
    }
    
    @inlinable
    func call<Params: Encodable, Res: ContextDecodable>(
        method: String, params: Params, context: Res.DecodingContext, _: Res.Type
    ) async throws -> Res {
        try await call(method: method, params: params, context: context)
    }
    
    @inlinable
    func call<Params: ContextEncodable, Res: ContextDecodable>(
        method: String, params: Params,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Res.DecodingContext, _: Res.Type
    ) async throws -> Res {
        try await call(method: method, params: params, encoding: econtext, decoding: dcontext)
    }
}

public extension RpcSubscribableClient {
    @inlinable
    func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String, _: Event.Type
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await subscribe(method: method, params: params, unsubscribe: umethod)
    }
    
    @inlinable
    func subscribe<Params: ContextEncodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String,
        context: Params.EncodingContext, _: Event.Type
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await subscribe(method: method, params: params, unsubscribe: umethod, context: context)
    }
    
    @inlinable
    func subscribe<Params: Encodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        context: Event.DecodingContext, _: Event.Type
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await subscribe(method: method, params: params, unsubscribe: umethod, context: context)
    }
    
    @inlinable
    func subscribe<Params: ContextEncodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Event.DecodingContext, _: Event.Type
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await subscribe(method: method, params: params,
                            unsubscribe: umethod, encoding: econtext, decoding: dcontext)
    }
}
