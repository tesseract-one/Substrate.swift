//
//  RpcBabeApi.swift
//  
//
//  Created by Ostap Danylovych on 30.04.2021.
//

import Foundation
import ScaleCodec

public struct SubstrateRpcBabeApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }

    // TODO rework, use Dictionary<AuthorityId, EpochAuthorship>
    public func epochAuthorship(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Dictionary<Data, Data>>) {
        substrate.client.call(
            method: "babe_epochAuthorship",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Dictionary<Data, Data>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}
