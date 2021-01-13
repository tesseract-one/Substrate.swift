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
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func properties(_ cb: @escaping SApiCallback<SystemProperties>) {
        Self.properties(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func properties(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SApiCallback<SystemProperties>
    ) {
        client.call(
            method: "system_properties",
            params: Array<Int>(),
            timeout: timeout
        ) { (res: RpcClientResult<SystemProperties>) in
            cb(res.mapError(SubstrateApiError.rpc))
        }
    }
}

extension SubstrateProtocol {
    public var system: SubstrateSystemApi<Self> { getApi(SubstrateSystemApi<Self>.self) }
}

