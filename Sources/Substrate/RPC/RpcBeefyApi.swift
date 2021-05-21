//
//  RpcBeefyApi.swift
//  
//
//  Created by Ostap Danylovych on 03.05.2021.
//

import Foundation

public struct SubstrateRpcBeefyApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: BeefyApi {
    public weak var substrate: S!
    public typealias BeefySignedCommitment = Data
    
    public init(substrate: S) {
        self.substrate = substrate
    }
}

extension SubstrateRpcBeefyApi where S.C: SubscribableRpcClient {
    public func subscribeJustifications(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<BeefySignedCommitment>) -> RpcSubscription {
        return substrate.client.subscribe(
            method: "beefy_subscribeJustifications",
            params: RpcCallParams(),
            unsubscribe: "beefy_unsubscribeJustifications"
        ) { (res: RpcClientResult<BeefySignedCommitment>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: BeefyApi {
    public var beefy: SubstrateRpcBeefyApi<S> { getRpcApi(SubstrateRpcBeefyApi<S>.self) }
}
