//
//  RpcAuthorApi.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public struct SubstrateRpcAuthorApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Session {
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
    
    public func pendingExtrinsics(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<[S.R.TExtrinsic]>
    ) {
        substrate.client.call(
            method: "author_pendingExtrinsics",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[Data]>) in
            let response = res.mapError(SubstrateRpcApiError.from).flatMap { dataArray in
                Result {
                    try dataArray.map { data in
                        try S.R.TExtrinsic(from: SCALE.default.decoder(data: data),
                                           registry: self.substrate.registry)
                    }
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }

    public func removeExtrinsic(
        bytesOrHash: [ExtrinsicOrHash<S.R>],
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<[S.R.THash]>
    ) {
        bytesOrHash.reduce(SRpcApiResult<[Data]>.success([])) { (prev, bOrH) in
            prev.flatMap { arr in
                self._encode(bOrH).map { arr + [$0] }
            }
        }.pour(error: cb).onSuccess { array in
            substrate.client.call(
                method: "author_removeExtrinsic",
                params: RpcCallParams(array),
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
    
    public func submit(
        extrinsic: S.R.TExtrinsic, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        _encode(extrinsic)
            .pour(error: cb)
            .onSuccess { data in
                substrate.client.call(
                    method: "author_submitExtrinsic",
                    params: RpcCallParams(data),
                    timeout: timeout ?? substrate.callTimeout
                ) { (res: RpcClientResult<S.R.THash>) in
                    cb(res.mapError(SubstrateRpcApiError.rpc))
                }
            }
    }
}

extension SubstrateRpcAuthorApi where S.C: SubscribableRpcClient {
    public func submitAndWatchExtrinsic(
        extrinsic: S.R.TExtrinsic,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<TransactionStatus<S.R.THash, S.R.THash>>
    ) -> RpcSubscription? {
        switch _encode(extrinsic) {
        case .failure(let err):
            cb(.failure(err))
            return nil
        case .success(let data):
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
}

extension SubstrateRpcApiRegistry where S.R: Session {
    public var author: SubstrateRpcAuthorApi<S> { getRpcApi(SubstrateRpcAuthorApi<S>.self) }
}

public enum ExtrinsicOrHash<R: Runtime>: ScaleDynamicEncodable {
    case hash(R.THash)
    case extrinsic(R.TExtrinsic)
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        switch self {
        case .hash(let h): try h.encode(in: encoder, registry: registry)
        case .extrinsic(let e): try e.encode(in: encoder, registry: registry)
        }
    }
}
