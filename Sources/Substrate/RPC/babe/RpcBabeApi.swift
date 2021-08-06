//
//  RpcBabeApi.swift
//  
//
//  Created by Ostap Danylovych on 30.04.2021.
//

import Foundation
import ScaleCodec

public struct SubstrateRpcBabeApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Babe {
    public typealias AuthorityId = S.R.TKeys.TBabe.TPublic
    
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }

    public func epochAuthorship(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Dictionary<AuthorityId, EpochAutorship>>
    ) {
        substrate.client.call(
            method: "babe_epochAuthorship",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Dictionary<Data, EpochAutorship>>) in
            let result = res
                .mapError(SubstrateRpcApiError.rpc)
                .flatMap { autorships in
                    Result(catching: { () -> Dictionary<AuthorityId, EpochAutorship> in
                        let tuples = try autorships.map {
                            try (AuthorityId(
                                    bytes: $0.key, format: self.substrate.properties.ss58Format
                            ), $0.value)
                        }
                        return Dictionary(tuples) { l, _ in l }
                    }).mapError(SubstrateRpcApiError.from)
                }
                
            cb(result)
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: Babe {
    public var babe: SubstrateRpcBabeApi<S> { getRpcApi(SubstrateRpcBabeApi<S>.self) }
}
