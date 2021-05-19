//
//  RpcAuthorApi.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public struct SubstrateRpcAuthorApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func hasKey(publicKey: Data, keyType: String, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Bool>) {
        substrate.client.call(
            method: "author_hasKey",
            params: RpcCallParams(publicKey, keyType),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Bool>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func hasSessionKeys(sessionKeys: Data, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Bool>) {
        substrate.client.call(
            method: "author_hasSessionKeys",
            params: RpcCallParams(sessionKeys),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Bool>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func insertKey(keyType: String, suri: String, publicKey: Data, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Data>) {
        substrate.client.call(
            method: "author_insertKey",
            params: RpcCallParams(keyType, suri, publicKey),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Data>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func pendingExtrinsics(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<[S.R.TExtrinsic]>) {
        substrate.client.call(
            method: "author_pendingExtrinsics",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[Data]>) in
            let response = res.mapError(SubstrateRpcApiError.from).flatMap { dataArray in
                Result {
                    try dataArray.map { data in
                        try S.R.TExtrinsic(data: data, registry: self.substrate.registry)
                    }
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }

    public func removeExtrinsic<H: Hash>(bytesOrHash: [ExtrinsicOrHash<H>], timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<[S.R.THash]>) {
        var hexArray = [Data]()
        for boh in bytesOrHash {
            switch boh {
            case .hash(let hash):
                guard let data = _encode(value: hash, cb) else { return }
                hexArray.append(data)
            case .extrinsic(let data):
                hexArray.append(data)
            }
        }
        substrate.client.call(
            method: "author_removeExtrinsic",
            params: RpcCallParams(hexArray),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[Data]>) in
            let response = res.mapError(SubstrateRpcApiError.from).flatMap { dataArray in
                Result {
                    try dataArray.map { try S.R.THash(decoding: $0) }
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }
    
    public func rotateKeys(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Data>) {
        substrate.client.call(
            method: "author_rotateKeys",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Data>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func submit<E: ExtrinsicProtocol>(
        extrinsic: E, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        guard let data = _encode(value: extrinsic, cb) else { return }
        substrate.client.call(
            method: "author_submitExtrinsic",
            params: RpcCallParams(data),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<S.R.THash>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcAuthorApi where S.C: SubscribableRpcClient {
    public func submitAndWatchExtrinsic<E: ExtrinsicProtocol>(
        extrinsic: E, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<TransactionStatus<S.R.THash, S.R.THash>>
    ) -> RpcSubscription? {
        guard let data = _encode(value: extrinsic, cb) else { return nil }
        return substrate.client.subscribe(
            method: "author_submitAndWatchExtrinsic",
            params: RpcCallParams(data),
            unsubscribe: "author_unwatchExtrinsic"
        ) { (res: Result<TransactionStatus<S.R.THash, S.R.THash>, RpcClientError>) in
            let response = res.mapError(SubstrateRpcApiError.rpc)
            cb(response)
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var author: SubstrateRpcAuthorApi<S> { getRpcApi(SubstrateRpcAuthorApi<S>.self) }
}

public enum ExtrinsicOrHash<H: Hash> {
    case hash(H)
    case extrinsic(Data)
}
