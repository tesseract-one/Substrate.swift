//
//  RpcBabeApi.swift
//  
//
//  Created by Ostap Danylovych on 30.04.2021.
//

import Foundation
import ScaleCodec

public struct SubstrateRpcBabeApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Session {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }

    // TODO rework, use Dictionary<AuthorityId, EpochAuthorship>
    public func epochAuthorship(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Dictionary<BabeAutorityId<S.R>, EpochAutorship>>
    ) {
        substrate.client.call(
            method: "babe_epochAuthorship",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Dictionary<String, EpochAutorship>>) in
            let result = res
                .mapError(SubstrateRpcApiError.rpc)
                .flatMap { autorships in
                    Result(catching: { () -> Dictionary<BabeAutorityId<S.R>, EpochAutorship> in
                        let tuples = try autorships.map {
                            try (BabeAutorityId<S.R>.from(ss58: $0.key).key, $0.value)
                        }
                        return Dictionary(tuples) { l, _ in l }
                    }).mapError(SubstrateRpcApiError.from)
                }
                
            cb(result)
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: Session {
    public var babe: SubstrateRpcBabeApi<S> { getRpcApi(SubstrateRpcBabeApi<S>.self) }
}

public typealias BabeAutorityId<R: Session> = R.TKeys.TBabe.TPublic

public struct EpochAutorship: Codable {
    public let primary: HexData
    public let secondary: HexData
    public let secondaryVrf: HexData
}
