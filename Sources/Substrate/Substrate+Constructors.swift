//
//  Substrate+Constructors.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc


extension Substrate {
    public static func create<R: Runtime, C: RpcClient>(
        client: C, runtime: R, _ cb: @escaping SRpcApiCallback<Substrate<R, C>>
    ) {
        _getRuntimeInfo(client: client, subs: Substrate<R, C>.self) { res in
            let result = res.flatMap { (meta, hash, version, props) in
               _createRegistry(meta: meta, runtime: runtime).map { registry in
                    Substrate<R, C>(
                        registry: registry, genesisHash: hash,
                        runtimeVersion: version, properties: props,
                        client: client)
                }
            }
            cb(result)
        }
    }
}

private extension Substrate {
    static func _createRegistry<R: Runtime>(meta: Metadata, runtime: R) -> SRpcApiResult<TypeRegistry> {
        return Result {
            let registry = TypeRegistry(metadata: meta)
            try runtime.registerEventsCallsAndTypes(in: registry)
            try registry.validate()
            return registry
        }.mapError(SubstrateRpcApiError.from)
    }
    
    static func _getRuntimeInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping SRpcApiCallback<(Metadata, S.R.THash, RuntimeVersion, SystemProperties)>
    ) {
        _getRuntimeVersionInfo(client: client, subs: subs) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success((let meta, let hash, let version)):
                SubstrateRpcSystemApi<S>.properties(client: client, timeout: 60) { res in
                    cb(res.map {(meta, hash, version, $0)})
                }
            }
        }
    }
    
    static func _getRuntimeVersionInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping SRpcApiCallback<(Metadata, S.R.THash, RuntimeVersion)>
    ) {
        _getRuntimeHashInfo(client: client, subs: subs) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success((let meta, let hash)):
                SubstrateRpcStateApi<S>.runtimeVersion(at: nil, with: client, timeout: 60) { res in
                    cb(res.map {(meta, hash, $0)})
                }
            }
        }
    }
    
    static func _getRuntimeHashInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping SRpcApiCallback<(Metadata, S.R.THash)>
    ) {
        _getRuntimeMetaInfo(client: client, subs: subs) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success(let meta):
                SubstrateRpcChainApi<S>.genesisHash(client: client, timeout: 60) { res in
                    cb(res.map {(meta, $0)})
                }
            }
        }
    }
    
    static func _getRuntimeMetaInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping SRpcApiCallback<Metadata>
    ) {
        SubstrateRpcStateApi<S>.metadata(client: client, timeout: 60, cb)
    }
}
