//
//  ChainApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public struct SubstrateChainApi<S: SubstrateProtocol>: SubstrateApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func genesisHash(_ cb: @escaping SApiCallback<S.R.THash>) {
        Self.genesisHash(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func genesisHash(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SApiCallback<S.R.THash>
    ) {
        client.call(
            method: "chain_getBlockHash",
            params: [0],
            timeout: timeout
        ) { (res: RpcClientResult<HexData>) in
            let response = res.mapError(SubstrateApiError.rpc).flatMap { data in
                Result { try S.R.THash(decoding: data.data) }.mapError(SubstrateApiError.from)
            }
            cb(response)
        }
    }
}

extension SubstrateProtocol {
    public var chain: SubstrateChainApi<Self> { getApi(SubstrateChainApi<Self>.self) }
}
