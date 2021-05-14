//
//  RpcChildstateApi.swift
//  
//
//  Created by Ostap Danylovych on 07.05.2021.
//

import Foundation

public struct SubstrateRpcChildstateApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    public typealias StorageKey = Data
    public typealias StorageData = Data
    public typealias PrefixedStorageKey = StorageKey
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func getKeys(childKey: PrefixedStorageKey, prefix: StorageKey, at: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<[StorageKey]>) {
        substrate.client.call(
            method: "childstate_getKeys",
            params: RpcCallParams(childKey, prefix, at),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[StorageKey]>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getStorage(childKey: PrefixedStorageKey, key: StorageKey, at: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<StorageData?>) {
        substrate.client.call(
            method: "childstate_getStorage",
            params: RpcCallParams(childKey, key, at),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<StorageData?>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getStorageHash(childKey: PrefixedStorageKey, key: StorageKey, at: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THash?>) {
        substrate.client.call(
            method: "childstate_getStorageHash",
            params: RpcCallParams(childKey, key, at),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<S.R.THash?>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getStorageSize(childKey: PrefixedStorageKey, key: StorageKey, at: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<UInt64?>) {
        substrate.client.call(
            method: "childstate_getStorageSize",
            params: RpcCallParams(childKey, key, at),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<UInt64?>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}
