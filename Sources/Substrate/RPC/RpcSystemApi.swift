//
//  RpcSystemApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public struct SubstrateRpcSystemApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func properties(_ cb: @escaping SRpcApiCallback<SystemProperties>) {
        Self.properties(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func properties(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<SystemProperties>
    ) {
        client.call(
            method: "system_properties",
            params: Array<Int>(),
            timeout: timeout
        ) { (res: RpcClientResult<SystemProperties>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var system: SubstrateRpcSystemApi<S> { getRpcApi(SubstrateRpcSystemApi<S>.self) }
}
