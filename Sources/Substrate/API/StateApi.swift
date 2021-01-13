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
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func runtimeVersion(at hash: S.R.THash? = nil, _ cb: @escaping SApiCallback<RuntimeVersion>) {
        Self.runtimeVersion(
            at: hash,
            with: substrate.client,
            timeout: substrate.callTimeout,
            cb
        )
    }
    
    public func metadata(_ cb: @escaping SApiCallback<Metadata>) {
        Self.metadata(client: substrate.client, timeout: substrate.callTimeout, cb)
    }
    
    public func getStorage(hash: Data, _ cb: @escaping SApiCallback<Data>) {
        substrate.client.call(
            method: "state_getStorage",
            params: [HexData(hash)],
            timeout: substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            cb(res.mapError(SubstrateApiError.rpc).map{$0.data})
        }
    }
    
    public func getStorage<K: StorageKey>(for key: K, _ cb: @escaping SApiCallback<K.Value>) {
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
                    }.mapError(SubstrateApiError.from)
                }
                cb(response)
            }
        } catch {
            cb(.failure(.from(error: error)))
        }
    }
    
    public func getStorage(dynamic key: AnyStorageKey, _ cb: @escaping SApiCallback<DValue>) {
        do {
            let registry = substrate.registry
            let prefix = try registry.prefix(for: key)
            let hkey = try registry.key(for: key)
            let vtype = try registry.valueType(for: key)
            getStorage(hash: prefix+hkey) { res in
                let response = res.flatMap { data in
                    Result {
                        try registry.decode(dynamic: vtype, from: SCALE.default.decoder(data: data))
                    }.mapError(SubstrateApiError.from)
                }
                cb(response)
            }
        } catch {
            cb(.failure(.from(error: error)))
        }
    }
    
    public static func runtimeVersion(
        at hash: S.R.THash?, with client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SApiCallback<RuntimeVersion>
    ) {
        do {
            let data = (try hash?.encode()).map(HexData.init)
            client.call(
                method: "state_getRuntimeVersion",
                params: [data],
                timeout: timeout
            ) { (res: RpcClientResult<RuntimeVersion>) in
                cb(res.mapError(SubstrateApiError.rpc))
            }
        } catch {
            cb(.failure(.from(error: error)))
        }
    }
    
    public static func metadata(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SApiCallback<Metadata>
    ) {
        client.call(
            method: "state_getMetadata",
            params: Array<Int>(),
            timeout: timeout
        ) { (res: RpcClientResult<HexData>) in
            let response: SApiResult<Metadata> = res.mapError(SubstrateApiError.rpc).flatMap { data in
                Result {
                    let decoder = SCALE.default.decoder(data: data.data)
                    let versioned = try decoder.decode(RuntimeVersionedMetadata.self)
                    return try Metadata(runtime: versioned.metadata)
                }.mapError(SubstrateApiError.from)
            }
            cb(response)
        }
    }
}

extension SubstrateProtocol {
    public var state: SubstrateStateApi<Self> { getApi(SubstrateStateApi<Self>.self) }
}

