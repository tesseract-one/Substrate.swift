//
//  RpcStateApi+Child.swift
//  
//
//  Created by Yehor Popovych on 10.08.2021.
//

import Foundation

extension SubstrateRpcStateApi { // Child methods
    public func getChildKeys(
        childStorageKey: Data,
        childDefinition: Data,
        childType: UInt32,
        key: Data,
        at hash: S.R.THash? = nil,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<[Data]>
    ) {
        substrate.client.call(
            method: "state_getChildKeys",
            params: RpcCallParams(childStorageKey, childDefinition, childType, key, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[Data]>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getChildReadProof(
        childStorageKey: Data,
        keys: Array<Data>,
        at hash: S.R.THash? = nil,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<ReadProof<S.R.THash>>
    ) {
        substrate.client.call(
            method: "state_getChildReadProof",
            params: RpcCallParams(childStorageKey, keys, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ReadProof<S.R.THash>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getChildStorage(
        childStorageKey: Data,
        childDefinition: Data,
        childType: UInt32,
        key: Data,
        at hash: S.R.THash? = nil,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Data>
    ) {
        substrate.client.call(
            method: "state_getChildStorage",
            params: RpcCallParams(childStorageKey, childDefinition, childType, key, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Data>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getChildStorageHash(
        childStorageKey: Data,
        childDefinition: Data,
        childType: UInt32,
        key: Data,
        at hash: S.R.THash? = nil,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        substrate.client.call(
            method: "state_getChildStorageHash",
            params: RpcCallParams(childStorageKey, childDefinition, childType, key, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<S.R.THash>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getChildStorageSize(
        childStorageKey: Data,
        childDefinition: Data,
        childType: UInt32,
        key: Data,
        at hash: S.R.THash? = nil,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<UInt64>
    ) {
        substrate.client.call(
            method: "state_getChildStorageSize",
            params: RpcCallParams(childStorageKey, childDefinition, childType, key, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<UInt64>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}
