//
//  RpcChainApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public struct SubstrateRpcChainApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    public typealias ChainBlock = SignedBlock<Block<S.R.THeader, S.R.TExtrinsic>>
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func getBlock(hash: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<ChainBlock>) {
        substrate.client.call(
            method: "chain_getBlock",
            params: RpcCallParams(hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ChainBlock>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getBlockHash(
        block: S.R.TBlockNumber?, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        Self.getBlockHash(
            block: block, client: substrate.client,
            timeout: timeout ?? substrate.callTimeout, cb
        )
    }
    
    public static func getBlockHash(
        block: S.R.TBlockNumber?, client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        client.call(
            method: "chain_getBlockHash",
            params: RpcCallParams(block),
            timeout: timeout
        ) { (res: RpcClientResult<HexData>) in
            let response = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result { try S.R.THash(decoding: data.data) }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var chain: SubstrateRpcChainApi<S> { getRpcApi(SubstrateRpcChainApi<S>.self) }
}
