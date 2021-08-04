//
//  RpcMmrApi.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public struct SubstrateRpcMmrApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func generateProof(
        leafIndex: UInt64,
        at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<MmrLeafProof<S.R.THash>>
    ) {
        substrate.client.call(
            method: "mmr_generateProof",
            params: RpcCallParams(leafIndex, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<MmrLeafProof<S.R.THash>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var mmr: SubstrateRpcMmrApi<S> { getRpcApi(SubstrateRpcMmrApi<S>.self) }
}

public struct MmrLeafProof<BH: Hash>: Decodable {
    public let blockHash: BH
    public let leaf: Data
    public let proof: Data
}
