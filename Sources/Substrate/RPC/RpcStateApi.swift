//
//  RpcStateApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC

public struct RpcStateApi<S: AnySubstrate>: RpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
//    public func call(
//        method: String, data: Data, at hash: S.R.THash?,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<Data>
//    ) {
//        substrate.client.call(
//            method: "state_call",
//            params: RpcCallParams(method, data, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { res in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func getKeys(prefix: Data,
//                        at hash: S.R.THash? = nil,
//                        timeout: TimeInterval? = nil,
//                        _ cb: @escaping SRpcApiCallback<Array<Data>>)
//    {
//        substrate.client.call(
//            method: "state_getKeys",
//            params: RpcCallParams(prefix, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<[Data]>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func getKeys(
//        for key: DStorageKey, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[DStorageKey]>
//    ) {
//        let registry = substrate.registry
//        _encode(key)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { prefix in
//                self.getKeys(prefix: prefix, at: hash, timeout: timeout) { res in
//                    let response = res.flatMap { keys in
//                        Result {
//                            try keys.map {
//                                try DStorageKey(module: key.module,
//                                                field: key.field,
//                                                decoder: SCALE.default.decoder(data: $0),
//                                                registry: registry)
//                            }
//                        }.mapError(SubstrateRpcApiError.from)
//                    }
//                    cb(response)
//                }
//            }
//    }
//
//    public func getKeys<SK: IterableStorageKey>(
//        prefix: Data, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[SK]>
//    ) {
//        let registry = substrate.registry
//        self.getKeys(prefix: prefix, at: hash, timeout: timeout) { res in
//            let response = res.flatMap { keys in
//                Result {
//                    try keys.map {
//                        try SK(from: SCALE.default.decoder(data: $0), registry: registry)
//                    }
//                }.mapError(SubstrateRpcApiError.from)
//            }
//            cb(response)
//        }
//    }
//
//    public func getKeys<SK: IterableStorageKey>(
//        for key: SK.IteratorKey, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[SK]>
//    ) {
//        let registry = substrate.registry
//        _try { try SK.iterator(key: key, registry: registry) }
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { prefix in
//                self.getKeys(prefix: prefix, at: hash, timeout: timeout, cb)
//            }
//    }
//
//    public func getKeysPaged(
//        prefix: Data, count: UInt32? = nil, startKey: Data? = nil,
//        at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[Data]>
//    ) {
//        let fcount = count ?? UInt32(substrate.pageSize)
//        substrate.client.call(
//            method: "state_getKeysPaged",
//            params: RpcCallParams(prefix, fcount, startKey, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<[Data]>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func getKeysPaged(
//        for key: DStorageKey, count: UInt32? = nil, startKey: DStorageKey? = nil,
//        at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[DStorageKey]>
//    ) {
//        let registry = substrate.registry
//        _encode(key)
//            .flatMap { iter in
//                startKey == nil
//                    ? .success((nil, iter))
//                    : self._encode(startKey!).map { ($0, iter) }
//            }
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { (start, iterator) in
//                getKeysPaged(
//                    prefix: iterator, count: count,
//                    startKey: start, at: hash, timeout: timeout
//                ) { result in
//                    let response = result.flatMap { keys in
//                        Result {
//                            try keys.map {
//                                try DStorageKey(module: key.module,
//                                                field: key.field,
//                                                decoder: SCALE.default.decoder(data: $0),
//                                                registry: registry)
//                            }
//                        }.mapError(SubstrateRpcApiError.from)
//                    }
//                    cb(response)
//                }
//            }
//    }
//
//    public func getKeysPaged<K: StorageKey>(
//        prefix: Data, count: UInt32? = nil, startKey: K? = nil,
//        at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[K]>
//    ) {
//        let registry = substrate.registry
//        let sKey: SRpcApiResult<Data?> = startKey == nil ? .success(nil) : _encode(startKey!).map{$0}
//        sKey.pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { start in
//                self.getKeysPaged(
//                    prefix: prefix, count: count,
//                    startKey: start, at: hash, timeout: timeout
//                ) { result in
//                    let response = result.flatMap { keys in
//                        Result {
//                            try keys.map {
//                                try K(from: SCALE.default.decoder(data: $0), registry: registry)
//                            }
//                        }.mapError(SubstrateRpcApiError.from)
//                    }
//                    cb(response)
//                }
//            }
//    }
//
//    public func getKeysPaged<K: IterableStorageKey>(
//        for key: K.IteratorKey, count: UInt32? = nil, startKey: K? = nil,
//        at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[K]>
//    ) {
//        let registry = substrate.registry
//        _try { try K.iterator(key: key, registry: registry) }
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { prefix in
//                self.getKeysPaged(
//                    prefix: prefix, count: count,
//                    startKey: startKey, at: hash, timeout: timeout, cb
//                )
//            }
//    }
//
//    public func getRuntimeVersion(
//        at hash: S.R.THash? = nil, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<RuntimeVersion>
//    ) {
//        Self.getRuntimeVersion(
//            at: hash,
//            with: substrate.client,
//            timeout: timeout ?? substrate.callTimeout,
//            cb
//        )
//    }
//
//    public func getMetadata(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Metadata>) {
//        Self.getMetadata(client: substrate.client, timeout: timeout ?? substrate.callTimeout, cb)
//    }
//
//    public func getReadProof(
//        keys: Array<Data>, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<ReadProof<S.R.THash>>
//    ) {
//        substrate.client.call(
//            method: "state_getKeys",
//            params: RpcCallParams(keys, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<ReadProof<S.R.THash>>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
    public func storage(raw key: Data, at hash: S.RC.THasher.THash? = nil) async throws -> Data {
        try await substrate.client.call(method: "state_getStorage", params: Params(key, hash))
    }
    
    public func storage<K: StorageKey>(key: K, at hash: S.RC.THasher.THash? = nil) async throws -> K.TValue {
        let data = try await storage(raw: key.hash(runtime: substrate.runtime), at: hash)
        return try key.decode(valueFrom: substrate.runtime.decoder(with: data),
                              runtime: substrate.runtime)
    }
    
    public func events(at hash: S.RC.THasher.THash? = nil) async throws -> Any {
        let data = try await storage(raw: substrate.runtime.eventsStorageKey.hash(runtime: substrate.runtime),
                                     at: hash)
        return data
    }
//
//    public func getStorage<K: StorageKey>(
//        for key: K, at hash: S.R.THash? = nil, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<K.Value>
//    ) {
//        let registry = substrate.registry
//        _encode(key)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { key in
//                self.getStorage(key: key, at: hash, timeout: timeout) { res in
//                    let response = res.flatMap { data in
//                        Result {
//                            try K.Value(from: SCALE.default.decoder(data: data), registry: registry)
//                        }.mapError(SubstrateRpcApiError.from)
//                    }
//                    cb(response)
//                }
//            }
//    }
//
//    public func getStorage(
//        for key: DStorageKey, at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<DValue>
//    ) {
//        let registry = substrate.registry
//        _encode(key)
//            .flatMap { khash in
//                _try { try registry.types(forKey: key.field, in: key.module) }.map { (khash, $0.last!) }
//            }
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { (key, vtype) in
//                getStorage(key: key, at: hash, timeout: timeout) { res in
//                    let response = res.flatMap { data in
//                        Result {
//                            try registry.decode(dynamic: vtype, from: SCALE.default.decoder(data: data))
//                        }.mapError(SubstrateRpcApiError.from)
//                    }
//                    cb(response)
//                }
//            }
//    }
//
//    public func getStorageHash(
//        key: Data, at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<S.R.THash>
//    ) {
//        substrate.client.call(
//            method: "state_getStorageHash",
//            params: RpcCallParams(key, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<S.R.THash>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//
//    public func getStorageHash<K: StorageKey>(
//        for key: K, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<S.R.THash>
//    ) {
//        _encode(key)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { key in
//                self.getStorageHash(key: key, at: hash, timeout: timeout, cb)
//            }
//    }
//
//    public func getStorageHash(
//        for key: DStorageKey, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<S.R.THash>
//    ) {
//        _encode(key)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { key in
//                self.getStorageHash(key: key, at: hash, timeout: timeout, cb)
//            }
//    }
//
//    public func getStorageSize(
//        key: Data, at hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<UInt64>
//    ) {
//        substrate.client.call(
//            method: "state_getStorageSize",
//            params: RpcCallParams(key, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<UInt64>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//
//    public func getStorageSize<K: StorageKey>(
//        for key: K, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<UInt64>
//    ) {
//        _encode(key)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { key in
//                self.getStorageSize(key: key, at: hash, timeout: timeout, cb)
//            }
//    }
//
//    public func getStorageSize(
//        for key: DStorageKey, at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<UInt64>
//    ) {
//        _encode(key)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { key in
//                self.getStorageSize(key: key, at: hash, timeout: timeout, cb)
//            }
//    }
//
//    public func queryStorage(
//        keys: Array<Data>,
//        from fBlock: S.R.THash,
//        to tBlock: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<StorageChangeSet<S.R.THash>>
//    ) {
//        let registry = substrate.registry
//        substrate.client.call(
//            method: "state_queryStorage",
//            params: RpcCallParams(keys, fBlock, tBlock),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<StorageChangeSetData<S.R.THash>>) in
//            let result = res
//                .mapError(SubstrateRpcApiError.rpc)
//                .flatMap { data in
//                    Result { try data.parse(registry: registry) }
//                        .mapError(SubstrateRpcApiError.from)
//                }
//            cb(result)
//        }
//    }
//
//
//    public func queryStorage(
//        keys: [AnyStorageKey],
//        from fBlock: S.R.THash,
//        to tBlock: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<StorageChangeSet<S.R.THash>>
//    ) {
//        _try {
//            try keys.map {
//                let encoder = SCALE.default.encoder()
//                try $0.encode(in: encoder, registry: substrate.registry)
//                return encoder.output
//            }
//        }
//        .pour(queue: substrate.client.responseQueue, error: cb)
//        .onSuccess { (keys: [Data]) in
//            self.queryStorage(keys: keys, from: fBlock, to: tBlock, timeout: timeout, cb)
//        }
//    }
//
//    public func queryStorageAt(
//        keys: Array<Data>,
//        at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<StorageChangeSet<S.R.THash>>
//    ) {
//        let registry = substrate.registry
//        substrate.client.call(
//            method: "state_queryStorageAt",
//            params: RpcCallParams(keys, hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<StorageChangeSetData<S.R.THash>>) in
//            let result = res
//                .mapError(SubstrateRpcApiError.rpc)
//                .flatMap { data in
//                    Result { try data.parse(registry: registry) }
//                        .mapError(SubstrateRpcApiError.from)
//                }
//            cb(result)
//        }
//    }
//
//    public func queryStorage(
//        keys: [AnyStorageKey],
//        at hash: S.R.THash? = nil,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<StorageChangeSet<S.R.THash>>
//    ) {
//        _try {
//            try keys.map {
//                let encoder = SCALE.default.encoder()
//                try $0.encode(in: encoder, registry: substrate.registry)
//                return encoder.output
//            }
//        }
//        .pour(queue: substrate.client.responseQueue, error: cb)
//        .onSuccess { (keys: [Data]) in
//            self.queryStorageAt(keys: keys, at: hash, timeout: timeout, cb)
//        }
//    }
//
//    public func traceBlock(
//        block: S.R.THash,
//        targets: String?,
//        storageKeys: String?,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<TraceBlockResponse>
//    ) {
//        substrate.client.call(
//            method: "state_traceBlock",
//            params: RpcCallParams(block, targets, storageKeys),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<TraceBlockResponse>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
}

extension RpcStateApi { // Static
    public static func runtimeVersion(
        at hash: S.RC.THasher.THash?, with client: CallableClient
    ) async throws -> S.RC.TRuntimeVersion {
        try await client.call(method: "state_getRuntimeVersion", params: Params(hash))
    }
    
    public static func metadata(with client: CallableClient) async throws -> Metadata {
        let data: Data = try await client.call(method: "state_getMetadata", params: Params())
        let versioned = try SCALE.default.decode(VersionedMetadata.self, from: data)
        return versioned.metadata
    }
}

extension RpcApiRegistry {
    public var state: RpcStateApi<S> { get async { await getRpcApi(RpcStateApi<S>.self) } }
}
