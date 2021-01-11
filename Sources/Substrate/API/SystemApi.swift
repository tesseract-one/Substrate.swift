//
//  SystemApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public struct SubstrateSystemApi<S: SubstrateProtocol>: SubstrateApi {
    private weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func properties(_ cb: @escaping (Result<SystemProperties, RpcClientError>) -> Void) {
        Self.properties(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func properties(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping (Result<SystemProperties, RpcClientError>) -> Void
    ) {
        client.call(
            method: "system_properties",
            params: Array<Int>(),
            timeout: timeout,
            response: cb)
    }
}

extension Substrate {
    public var system: SubstrateSystemApi<Substrate<R>> { getApi(SubstrateSystemApi<Substrate<R>>.self) }
}

extension SubscribableSubstrate {
    public var system: SubstrateSystemApi<SubscribableSubstrate<R>> {
        getApi(SubstrateSystemApi<SubscribableSubstrate<R>>.self)
    }
}
