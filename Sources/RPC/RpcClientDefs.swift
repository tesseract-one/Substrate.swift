//
//  RpcClientDefs.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation

public protocol RpcCallableClient {
    func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res
}

public protocol RpcSubscribableClient: RpcCallableClient {
    func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String
    ) async throws -> AsyncThrowingStream<Event, Error>
}

public extension RpcCallableClient {
    func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params, _ res: Res.Type
    ) async throws -> Res {
        return try await call(method: method, params: params)
    }
}

public extension RpcSubscribableClient {
    func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String, _ event: Event.Type
    ) async throws -> AsyncThrowingStream<Event, Error> {
        return try await subscribe(method: method, params: params, unsubscribe: umethod)
    }
}
