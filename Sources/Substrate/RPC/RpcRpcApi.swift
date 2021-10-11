//
//  RpcRpcApi.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct SubstrateRpcRpcApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func methods(
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<RpcMethods>
    ) {
        substrate.client.call(
            method: "rpc_methods",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<RpcMethods>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var rpc: SubstrateRpcRpcApi<S> { getRpcApi(SubstrateRpcRpcApi<S>.self) }
}

public struct RpcMethods: Codable {
    public let version: UInt32
    public let methods: Array<String>
}
