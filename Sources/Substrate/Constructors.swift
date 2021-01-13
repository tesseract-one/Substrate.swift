//
//  Constructors.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc


extension Substrate {
    public static func create<R: Runtime, C: RpcClient>(
        client: C, runtime: R, _ cb: @escaping (Result<Substrate<R, C>, Error>) -> Void
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
    static func _createRegistry<R: Runtime>(meta: Metadata, runtime: R) -> Result<TypeRegistry, Error> {
        return Result {
            let registry = TypeRegistry(metadata: meta)
            try runtime.register(in: registry)
            try registry.validate()
            return registry
        }
    }
    
    static func _getRuntimeInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping (Result<(Metadata, S.R.THash, RuntimeVersion, SystemProperties), Error>) -> Void
    ) {
        _getRuntimeVersionInfo(client: client, subs: subs) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success((let meta, let hash, let version)):
                SubstrateSystemApi<S>.properties(client: client, timeout: 60) { res in
                    switch res {
                    case .failure(let err): cb(.failure(err))
                    case .success(let props):
                        cb(.success((meta, hash, version, props)))
                    }
                }
            }
        }
    }
    
    static func _getRuntimeVersionInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping (Result<(Metadata, S.R.THash, RuntimeVersion), Error>) -> Void
    ) {
        _getRuntimeHashInfo(client: client, subs: subs) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success((let meta, let hash)):
                SubstrateStateApi<S>.runtimeVersion(at: nil, with: client, timeout: 60) { res in
                    switch res {
                    case .failure(let err): cb(.failure(err))
                    case .success(let version):
                        cb(.success((meta, hash, version)))
                    }
                }
            }
        }
    }
    
    static func _getRuntimeHashInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping (Result<(Metadata, S.R.THash), Error>) -> Void
    ) {
        _getRuntimeMetaInfo(client: client, subs: subs) { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success(let meta):
                SubstrateChainApi<S>.genesisHash(client: client, timeout: 60) { res in
                    switch res {
                    case .failure(let err): cb(.failure(err))
                    case .success(let hash):
                        cb(.success((meta, hash)))
                    }
                }
            }
        }
    }
    
    static func _getRuntimeMetaInfo<S: SubstrateProtocol>(
        client: RpcClient, subs: S.Type,
        cb: @escaping (Result<Metadata, Error>) -> Void
    ) {
        SubstrateStateApi<S>.metadata(client: client, timeout: 60, cb)
    }
}
