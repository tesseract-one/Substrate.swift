//
//  RpcGrandpaApi.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public struct SubstrateRpcGrandpaApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Grandpa {
    public typealias AuthorityId = S.R.TKeys.TGrandpa.TPublic
    public typealias EncodedFinalityProofs = Data
    public typealias JustificationNotification = Data
    
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func proveFinality(
        begin: S.R.THash, end: S.R.THash,
        authoritiesSetId: UInt64?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<Optional<EncodedFinalityProofs>>
    ) {
        substrate.client.call(
            method: "grandpa_proveFinality",
            params: RpcCallParams(begin, end, authoritiesSetId),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Optional<EncodedFinalityProofs>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func roundState(
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<ReportedRoundStates<AuthorityId>>
    ) {
        substrate.client.call(
            method: "grandpa_roundState",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ReportedRoundStates<AuthorityId>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcGrandpaApi where S.C: SubscribableRpcClient {
    public func subscribeJustifications(
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<JustificationNotification>
    ) -> RpcSubscription {
        substrate.client.subscribe(
            method: "grandpa_subscribeJustifications",
            params: RpcCallParams(),
            unsubscribe: "grandpa_unsubscribeJustifications"
        ) { (res: Result<JustificationNotification, RpcClientError>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: Grandpa {
    public var grandpa: SubstrateRpcGrandpaApi<S> { getRpcApi(SubstrateRpcGrandpaApi<S>.self) }
}
