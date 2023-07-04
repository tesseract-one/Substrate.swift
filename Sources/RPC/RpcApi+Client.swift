//
//  RpcApi+Client.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
#if !COCOAPODS
import Substrate
#endif

extension RpcApiRegistry: RpcCallableClient where R.CL: RpcCallableClient {
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await rootApi.client.call(method: method, params: params)
    }
}

extension RpcApiRegistry: RpcSubscribableClient where R.CL: RpcSubscribableClient {
    public func subscribe<P: Encodable, E: Decodable>(
        method: String, params: P, unsubscribe umethod: String
    ) async throws -> AsyncThrowingStream<E, Error> {
        try await rootApi.client.subscribe(method: method, params: params, unsubscribe: umethod)
    }
    
    public func subscribe<P: Encodable, E: Decodable>(
        method: String, params: P, unsubscribe umethod: String, _ event: E.Type
    ) async throws -> AsyncThrowingStream<E, Error> {
        try await rootApi.client.subscribe(method: method, params: params, unsubscribe: umethod)
    }
}

public extension RpcApiRegistry where R.CL: RpcCallableClient {
    func methods() async throws -> Set<String> {
        try await RpcClient<R.RC, R.CL>.rpcMethods(client: rootApi.client)
    }
}
