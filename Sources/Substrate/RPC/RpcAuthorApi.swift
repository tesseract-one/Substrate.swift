//
//  RpcAuthorApi.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public struct SubstrateRpcAuthorApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func submit<E: ScaleDynamicEncodable>(
        extrinsic: E, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        guard let data = encode(value: extrinsic, cb) else { return }
        substrate.client.call(
            method: "author_submitExtrinsic",
            params: [HexData(data)],
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            let response = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result { try S.R.THash(decoding: data.data) }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var author: SubstrateRpcAuthorApi<S> { getRpcApi(SubstrateRpcAuthorApi<S>.self) }
}
