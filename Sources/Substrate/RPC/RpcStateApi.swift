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
    
    public func getStorage(keyHash: Data, hash: S.R.THash? = nil, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Data>) {
        let hashData = try! hash.map { try HexData($0.encode()) } // Hash doesn't throw errors
        substrate.client.call(
            method: "state_getStorage",
            params: [HexData(keyHash), hashData],
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            cb(res.mapError(SubstrateRpcApiError.rpc).map{$0.data})
        }
    }
    
    public func getStorage<K: StaticStorageKey>(
        for key: K, hash: S.R.THash? = nil, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<K.Value>
    ) {
        do {
            let registry = substrate.registry
            let keyHash = try registry.hash(of: key)
            let vtype = try registry.type(valueOf: key)
            getStorage(keyHash: keyHash, hash: hash, timeout: timeout) { res in
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
        } catch {
            cb(.failure(.from(error: error)))
        }
    }
    
    public func getStorage<K: DynamicStorageKey>(
        for key: K, hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<DValue>
    ) {
        do {
            let registry = substrate.registry
            let keyHash = try registry.hash(of: key)
            let vtype = try registry.type(valueOf: key)
            getStorage(keyHash: keyHash, hash: hash, timeout: timeout) { res in
                let response = res.flatMap { data in
                    Result {
                        try registry.decode(dynamic: vtype, from: SCALE.default.decoder(data: data))
                    }.mapError(SubstrateRpcApiError.from)
                }
                cb(response)
            }
        } catch {
            cb(.failure(.from(error: error)))
        }
    }
    
    public static func runtimeVersion(
        at hash: S.R.THash?, with client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<RuntimeVersion>
    ) {
        do {
            let data = (try hash?.encode()).map(HexData.init)
            client.call(
                method: "state_getRuntimeVersion",
                params: [data],
                timeout: timeout
            ) { (res: RpcClientResult<RuntimeVersion>) in
                cb(res.mapError(SubstrateRpcApiError.rpc))
            }
        } catch {
            cb(.failure(.from(error: error)))
        }
    }
    
    public static func metadata(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<Metadata>
    ) {
        client.call(
            method: "state_getMetadata",
            params: Array<Int>(),
            timeout: timeout
        ) { (res: RpcClientResult<HexData>) in
            let response: SRpcApiResult<Metadata> = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result {
                    let decoder = SCALE.default.decoder(data: data.data)
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

