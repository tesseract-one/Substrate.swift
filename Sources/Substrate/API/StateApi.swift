//
//  StateApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public struct SubstrateStateApi<S: SubstrateProtocol>: SubstrateApi {
    private weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func runtimeVersion(at hash: S.R.Hash? = nil, _ cb: @escaping (Result<RuntimeVersion, RpcClientError>) -> Void) {
        Self.runtimeVersion(
            at: hash,
            with: substrate.client,
            timeout: substrate.callTimeout,
            cb
        )
    }
    
    public func metadata(_ cb: @escaping (Result<Metadata, Error>) -> Void) {
        Self.metadata(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public static func runtimeVersion(
        at hash: S.R.Hash?, with client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping (Result<RuntimeVersion, RpcClientError>) -> Void
    ) {
        client.call(
            method: "state_getRuntimeVersion",
            params: [hash],
            timeout: timeout,
            response: cb
        )
    }
    
    public static func metadata(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping (Result<Metadata, Error>) -> Void
    ) {
        client.call(
            method: "state_getMetadata",
            params: Array<Int>(),
            timeout: timeout
        ) { (res: Result<HexData, RpcClientError>) in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success(let data):
                do {
                    let decoder = SCALE.default.decoder(data: data.data)
                    let versioned = try decoder.decode(RuntimeVersionedMetadata.self)
                    let metadata = try Metadata(runtime: versioned.metadata)
                    cb(.success(metadata))
                } catch {
                    cb(.failure(error))
                }
            }
        }
    }
}

extension Substrate {
    public var state: SubstrateStateApi<Substrate<R>> { getApi(SubstrateStateApi<Substrate<R>>.self) }
}

extension SubscribableSubstrate {
    public var state: SubstrateStateApi<SubscribableSubstrate<R>> { getApi(SubstrateStateApi<SubscribableSubstrate<R>>.self) }
}
