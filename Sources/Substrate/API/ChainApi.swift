//
//  ChainApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public protocol SubstrateChainApiCommon: SubstrateApi {
    var substrate: S! { get }
}

extension SubstrateChainApiCommon {
    public func genesisHash(_ cb: @escaping (Result<S.R.Hash, RpcClientError>) -> Void) {
        Self.genesisHash(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func genesisHash(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping (Result<S.R.Hash, RpcClientError>) -> Void
    ) {
        client.call(
            method: "chain_getBlockHash",
            params: [0],
            timeout: timeout,
            response: cb)
    }
}

public struct SubstrateChainApi<S: SubstrateProtocol>: SubstrateChainApiCommon {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
}

public struct SubstrateChainApiSubscribable<S: SubscribableSubstrateProtocol>: SubstrateChainApiCommon {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
}

extension Substrate {
    public var chain: SubstrateChainApi<Substrate<R>> { getApi(SubstrateChainApi<Substrate<R>>.self) }
}

extension SubscribableSubstrate {
    public var chain: SubstrateChainApiSubscribable<SubscribableSubstrate<R>> {
        getApi(SubstrateChainApiSubscribable<SubscribableSubstrate<R>>.self)
    }
}
