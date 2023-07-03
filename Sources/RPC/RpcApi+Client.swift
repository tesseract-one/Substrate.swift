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

extension RpcApiRegistry: RpcCallableClient where S.CL: RpcCallableClient {
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await substrate.client.call(method: method, params: params)
    }
}

extension RpcApiRegistry: RpcSubscribableClient where S.CL: RpcSubscribableClient {
    public func subscribe<P: Encodable, E: Decodable>(
        method: String, params: P, unsubsribe umethod: String
    ) async throws -> AsyncThrowingStream<E, Error> {
        try await substrate.client.subscribe(method: method, params: params, unsubsribe: umethod)
    }
}

public extension RpcApiRegistry where S.CL: RpcCallableClient {
    func methods() async throws -> Set<String> {
        try await RpcClient<S.RC, S.CL>.rpcMethods(client: substrate.client)
    }
}
