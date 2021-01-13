//
//  AuthorApi.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public struct SubstrateAuthorApi<S: SubstrateProtocol>: SubstrateApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func submit<E: ScaleDynamicEncodable>(extrinsic: E, _ cb: @escaping SApiCallback<S.R.THash>) {
        guard let data = encode(value: extrinsic, cb) else { return }
        substrate.client.call(
            method: "author_submitExtrinsic",
            params: [HexData(data)],
            timeout: substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            let response = res.mapError(SubstrateApiError.rpc).flatMap { data in
                Result { try S.R.THash(decoding: data.data) }.mapError(SubstrateApiError.from)
            }
            cb(response)
        }
    }
}

extension SubstrateProtocol {
    public var author: SubstrateAuthorApi<Self> { getApi(SubstrateAuthorApi<Self>.self) }
}
