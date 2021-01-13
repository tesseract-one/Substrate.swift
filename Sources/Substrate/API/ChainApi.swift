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
    
    public func genesisHash(_ cb: @escaping (Result<S.R.THash, RpcClientError>) -> Void) {
        Self.genesisHash(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func genesisHash(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping (Result<S.R.THash, RpcClientError>) -> Void
    ) {
        client.call(
            method: "chain_getBlockHash",
            params: [0],
            timeout: timeout
        ) { (res: Result<HexData, RpcClientError>) in
            let response = res.flatMap { data in
                Result { try S.R.THash(decoding: data.data) }.mapError(RpcClientError.unknown)
            }
            cb(response)
        }
    }
}

// SubscribableTest
extension SubstrateChainApi where S.C: SubscribableRpcClient {
    public func testSubs(text:  String) {}
}

extension Substrate {
    public var chain: SubstrateChainApi<Substrate<R, C>> { getApi(SubstrateChainApi<Substrate<R, C>>.self) }
}
