//
//  RpcSyncStateApi.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation
import Serializable

public struct SubstrateRpcSyncStateApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func genSyncSpec(
        raw: Bool,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<SerializableValue>
    ) {
        substrate.client.call(
            method: "sync_state_genSyncSpec",
            params: RpcCallParams(raw),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<SerializableValue>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var syncstate: SubstrateRpcSyncStateApi<S> { getRpcApi(SubstrateRpcSyncStateApi<S>.self) }
}
