//
//  RpcStateApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec


public struct SubstrateRpcStateApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func runtimeVersion(
        at hash: S.R.THash? = nil, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<RuntimeVersion>
    ) {
        Self.runtimeVersion(
            at: hash,
            with: substrate.client,
            timeout: timeout ?? substrate.callTimeout,
            cb
        )
    }
    
    public func metadata(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Metadata>) {
        Self.metadata(client: substrate.client, timeout: timeout ?? substrate.callTimeout, cb)
    }
    
    public func getStorage(
        keyHash: Data, at: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Data>
    ) {
        substrate.client.call(
            method: "state_getStorage",
            params: RpcCallParams(keyHash, at),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Data>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getKeysPaged(
        iteratorHash: Data, count: UInt32? = nil, startKeyHash: Data? = nil,
        at: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<[Data]>
    ) {
        let fcount = count ?? UInt32(substrate.pageSize)
        substrate.client.call(
            method: "state_getKeysPaged",
            params: RpcCallParams(iteratorHash, fcount, startKeyHash, at),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[Data]>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getKeysPaged<K: DynamicStorageKey>(
        for key: K, count: UInt32? = nil, startKey: K? = nil,
        at: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<[K]>
    ) {
        let registry = substrate.registry
        _try {
            (try startKey.map { try registry.hash(of: $0) }, try registry.hash(iteratorOf: key))
        }.pour(queue: substrate.client.responseQueue, error: cb)
        .onSuccess { (start, iterator) in
            getKeysPaged(
                iteratorHash: iterator, count: count,
                startKeyHash: start, at: at, timeout: timeout
            ) { result in
                let response = result.flatMap { keys in
                    Result {
                        try keys.map {
                            try registry.decode(key: K.self, module: key.module, field: key.field, from: $0)
                        }
                    }.mapError(SubstrateRpcApiError.from)
                }
                cb(response)
            }
        }
    }
    
    public func getKeysPaged<K: IterableStaticStorageKey>(
        for key: K, count: UInt32? = nil, startKey: K? = nil,
        at: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<[K]>
    ) {
        let registry = substrate.registry
        _try {
            (try startKey.map { try registry.hash(of: $0) }, try registry.hash(iteratorOf: key))
        }.pour(queue: substrate.client.responseQueue, error: cb)
        .onSuccess { (start, iterator) in
            getKeysPaged(
                iteratorHash: iterator, count: count,
                startKeyHash: start, at: at, timeout: timeout
            ) { result in
                let response = result.flatMap { keys in
                    Result {
                        try keys.map { try registry.decode(key: K.self, from: $0) }
                    }.mapError(SubstrateRpcApiError.from)
                }
                cb(response)
            }
        }
    }
    
    public func getStorage<K: StaticStorageKey>(
        for key: K, at: S.R.THash? = nil, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<K.Value>
    ) {
        let registry = substrate.registry
        _try { try (registry.hash(of: key), registry.type(valueOf: key)) }
            .pour(error: cb)
            .onSuccess { (keyHash, vtype) in
                getStorage(keyHash: keyHash, at: at, timeout: timeout) { res in
                    let response = res.flatMap { data in
                        Result {
                            try registry.decode(
                                static: K.Value.self, as: vtype,
                                from: SCALE.default.decoder(data: data)
                            )
                        }.mapError(SubstrateRpcApiError.from)
                    }
                    cb(response)
                }
            }
    }
    
    public func getStorage<K: DynamicStorageKey>(
        for key: K, at: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<DValue>
    ) {
        let registry = substrate.registry
        _try { try (registry.hash(of: key), registry.type(valueOf: key)) }
            .pour(error: cb)
            .onSuccess { (keyHash, vtype) in
                getStorage(keyHash: keyHash, at: at, timeout: timeout) { res in
                    let response = res.flatMap { data in
                        Result {
                            try registry.decode(dynamic: vtype, from: SCALE.default.decoder(data: data))
                        }.mapError(SubstrateRpcApiError.from)
                    }
                    cb(response)
                }
            }
    }
    
    public static func runtimeVersion(
        at hash: S.R.THash?, with client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<RuntimeVersion>
    ) {
        client.call(
            method: "state_getRuntimeVersion",
            params: RpcCallParams(hash),
            timeout: timeout
        ) { (res: RpcClientResult<RuntimeVersion>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public static func metadata(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<Metadata>
    ) {
        client.call(
            method: "state_getMetadata",
            params: RpcCallParams(),
            timeout: timeout
        ) { (res: RpcClientResult<Data>) in
            let response: SRpcApiResult<Metadata> = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result {
                    let decoder = SCALE.default.decoder(data: data)
                    let versioned = try decoder.decode(RuntimeVersionedMetadata.self)
                    return try Metadata(runtime: versioned.metadata)
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var state: SubstrateRpcStateApi<S> { getRpcApi(SubstrateRpcStateApi<S>.self) }
}
