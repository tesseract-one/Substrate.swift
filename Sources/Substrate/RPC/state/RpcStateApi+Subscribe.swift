//
//  RpcStateApi+Subscribe.swift
//  
//
//  Created by Yehor Popovych on 10.08.2021.
//

import Foundation

extension SubstrateRpcStateApi where S.C: SubscribableRpcClient {
    public func subscribeRuntimeVersion(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<RuntimeVersion>
    ) -> RpcSubscription {
        return substrate.client.subscribe(
            method: "state_subscribeRuntimeVersion",
            params: RpcCallParams(),
            unsubscribe: "state_unsubscribeRuntimeVersion"
        ) { (res: RpcClientResult<RuntimeVersion>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func subscribeStorage(
        keys: Array<Data>?,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<StorageChangeSet<S.R.THash>>
    ) -> RpcSubscription {
        let registry = substrate.registry
        return substrate.client.subscribe(
            method: "state_subscribeStorage",
            params: RpcCallParams(),
            unsubscribe: "state_unsubscribeStorage"
        ) { (res: RpcClientResult<StorageChangeSetData<S.R.THash>>) in
            let result = res
                .mapError(SubstrateRpcApiError.rpc)
                .flatMap { data in
                    Result { try data.parse(registry: registry) }
                        .mapError(SubstrateRpcApiError.from)
                }
            cb(result)
        }
    }
    
    public func subscribeStorage(
        keys: [AnyStorageKey]?,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<StorageChangeSet<S.R.THash>>
    ) -> RpcSubscription? {
        return try! _try {
            try keys.map { (keys: [AnyStorageKey]) -> [Data] in
                try keys.map { (key: AnyStorageKey) -> Data in
                    let encoder = SCALE.default.encoder()
                    try key.encode(in: encoder, registry: substrate.registry)
                    return encoder.output
                }
            }
        }
        .mapError(SubstrateRpcApiError.from)
        .map { (keys: [Data]?) -> RpcSubscription in
            self.subscribeStorage(keys: keys, timeout: timeout, cb)
        }
        .flatMapError { err -> Result<RpcSubscription?, NoError> in
            cb(.failure(err))
            return .success(nil)
        }
        .get()
    }
}
