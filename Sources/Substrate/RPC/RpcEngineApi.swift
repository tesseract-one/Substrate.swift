//
//  RpcEngineApi.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public struct SubstrateRpcEngineApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func createBlock(
        empty: Bool, finalize: Bool, parentHash: S.R.THash?, timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<CreatedBlock<S.R.THash>>
    ) {
        substrate.client.call(
            method: "engine_createBlock",
            params: RpcCallParams(empty, finalize, parentHash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<CreatedBlock<S.R.THash>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func finalizeBlock(
        hash: S.R.THash, justification: Justification?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<Bool>
    ) {
        substrate.client.call(
            method: "engine_finalizeBlock",
            params: RpcCallParams(hash, justification),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Bool>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var engine: SubstrateRpcEngineApi<S> { getRpcApi(SubstrateRpcEngineApi<S>.self) }
}


public struct CreatedBlock<H: Hash>: Decodable {
    public let hash: H
    public let aux: ImportedAux
}

public struct ImportedAux: Decodable {
    public let headerOnly: Bool
    public let clearJustificationRequests: Bool
    public let needsJustification: Bool
    public let badJustification: Bool
    public let needsFinalityProof: Bool
    public let isNewBest: Bool
}
