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
    
    public func runtimeVersion(at hash: S.R.THash? = nil, _ cb: @escaping SRpcApiCallback<RuntimeVersion>) {
        Self.runtimeVersion(
            at: hash,
            with: substrate.client,
            timeout: substrate.callTimeout,
            cb
        )
    }
    
    public func metadata(_ cb: @escaping SRpcApiCallback<Metadata>) {
        Self.metadata(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public func getStorage(hash: Data, _ cb: @escaping SRpcApiCallback<Data>) {
        substrate.client.call(
            method: "state_getStorage",
            params: [HexData(hash)],
            timeout: substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            cb(res.mapError(SubstrateRpcApiError.rpc).map{$0.data})
        }
    }
    
    public func getStorage<K: StorageKey>(for key: K, _ cb: @escaping SRpcApiCallback<K.Value>) {
        do {
            let registry = substrate.registry
            let prefix = try registry.prefix(for: key)
            let hkey = try registry.key(for: key)
            let vtype = try registry.valueType(for: key)
            getStorage(hash: prefix+hkey) { res in
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
    
    public func getStorage(dynamic key: AnyStorageKey, _ cb: @escaping SRpcApiCallback<DValue>) {
        do {
            let registry = substrate.registry
            let prefix = try registry.prefix(for: key)
            let hkey = try registry.key(for: key)
            let vtype = try registry.valueType(for: key)
            getStorage(hash: prefix+hkey) { res in
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

