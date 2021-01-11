//
//  Constructors.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc

extension SubstrateProtocol {
    public static func create<R: Runtime, C: RpcClient>(
        rpc: C, runtime: R, _ cb: @escaping (Result<Substrate<R>, Error>) -> Void
    ) {
        let registry = TypeRegistry()
        do {
            try runtime.registerTypes(registry: registry)
        } catch {
            cb(.failure(error))
            return
        }
        _getRuntimeInfo(client: rpc, registry: registry, subs: Substrate<R>.self) { res in
            let result = res.map { (meta, hash, version, props) in
                Substrate<R>(
                    metadata: meta, genesisHash: hash,
                    runtimeVersion: version, properties: props,
                    client: rpc)
            }
            cb(result)
        }
    }
    
    public static func create<R: Runtime, C: SubscribableRpcClient>(
        subRpc: C, runtime: R, _ cb: @escaping (Result<SubscribableSubstrate<R>, Error>) -> Void
    ) {
        let registry = TypeRegistry()
        do {
            try runtime.registerTypes(registry: registry)
        } catch {
            cb(.failure(error))
            return
        }
        _getRuntimeInfo(client: subRpc, registry: registry, subs: SubscribableSubstrate<R>.self) { res in
            let result = res.map { (meta, hash, version, props) in
                SubscribableSubstrate<R>(
                    metadata: meta, genesisHash: hash,
                    runtimeVersion: version, properties: props,
                    client: subRpc)
            }
            cb(result)
        }
    }
}

private extension SubstrateProtocol {
    static func _getRuntimeInfo<S: SubstrateProtocol>(
        client: RpcClient, registry: TypeRegistryProtocol, subs: S.Type,
        cb: @escaping (Result<(Metadata, S.R.Hash, RuntimeVersion, SystemProperties), Error>) -> Void
    ) {
        _getRuntimeVersionInfo(client: client, registry: registry, subs: subs) { res in
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
        client: RpcClient, registry: TypeRegistryProtocol, subs: S.Type,
        cb: @escaping (Result<(Metadata, S.R.Hash, RuntimeVersion), Error>) -> Void
    ) {
        _getRuntimeHashInfo(client: client, registry: registry, subs: subs) { res in
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
        client: RpcClient, registry: TypeRegistryProtocol, subs: S.Type,
        cb: @escaping (Result<(Metadata, S.R.Hash), Error>) -> Void
    ) {
        _getRuntimeMetaInfo(client: client, registry: registry, subs: subs) { res in
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
        client: RpcClient, registry: TypeRegistryProtocol, subs: S.Type,
        cb: @escaping (Result<Metadata, Error>) -> Void
    ) {
        SubstrateStateApi<S>.metadata(client: client, timeout: 60, registry: registry, cb)
    }
}
