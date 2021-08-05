//
//  RpcBeefyApi.swift
//  
//
//  Created by Ostap Danylovych on 03.05.2021.
//

import Foundation

public struct SubstrateRpcBeefyApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: BeefyApi {
    public weak var substrate: S!
    
    public typealias SignedCommitment = BeefySignedCommitment<
        S.R.TBeefyPayload, S.R.TBlockNumber, S.R.TBeefyValidatorSetId, S.R.TBeefySignature
    >
    
    public init(substrate: S) {
        self.substrate = substrate
    }
}

extension SubstrateRpcBeefyApi where S.C: SubscribableRpcClient {
    public func subscribeJustifications(
        timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<SignedCommitment>
    ) -> RpcSubscription {
        let registry = substrate.registry
        return substrate.client.subscribe(
            method: "beefy_subscribeJustifications",
            params: RpcCallParams(),
            unsubscribe: "beefy_unsubscribeJustifications"
        ) { (res: RpcClientResult<Data>) in
            let result = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result {
                    try SignedCommitment(from: SCALE.default.decoder(data: data), registry: registry)
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(result)
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: BeefyApi {
    public var beefy: SubstrateRpcBeefyApi<S> { getRpcApi(SubstrateRpcBeefyApi<S>.self) }
}
