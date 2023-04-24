//
//  RpcRpcApi.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation
import JsonRPC

public struct RpcRpcApi<S: SomeSubstrate>: RpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public struct Methods: Codable {
        public let methods: Set<String>
    }
    
    public func methods() async throws -> Methods {
        try await substrate.client.call(method: "rpc_methods", params: Params())
    }
}

extension RpcApiRegistry {
    public var rpc: RpcRpcApi<S> { get async { await getApi(RpcRpcApi<S>.self) } }
}

