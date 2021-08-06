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

extension SubstrateRpcAuthorApi where S.R: Session {
    public func hasKey<K: PublicKey>(
        publicKey: K, keyType: KeyTypeId,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Bool>
    ) {
        substrate.client.call(
            method: "author_hasKey",
            params: RpcCallParams(publicKey.bytes, keyType.rawValue),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Bool>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func hasSessionKeys(
        keys: S.R.TKeys,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Bool>
    ) {
        _encode(keys)
            .pour(error: cb)
            .onSuccess { data in
                substrate.client.call(
                    method: "author_hasSessionKeys",
                    params: RpcCallParams(data),
                    timeout: timeout ?? substrate.callTimeout
                ) { (res: RpcClientResult<Bool>) in
                    cb(res.mapError(SubstrateRpcApiError.rpc))
                }
            }
    }
    
    public func insertKey<K: PublicKey>(
        keyType: KeyTypeId, suri: String, publicKey: K,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Data>
    ) {
        substrate.client.call(
            method: "author_insertKey",
            params: RpcCallParams(keyType.rawValue, suri, publicKey.bytes),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Data>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func rotateKeys(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<S.R.TKeys>
    ) {
        let registry = substrate.registry
        substrate.client.call(
            method: "author_rotateKeys",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Data>) in
            let result = res
                .mapError(SubstrateRpcApiError.rpc)
                .flatMap { data in
                    Result {
                        try S.R.TKeys(from: SCALE.default.decoder(data: data),
                                      registry: registry)
                    }.mapError(SubstrateRpcApiError.from)
                }
            cb(result)
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

extension SubstrateRpcApiRegistry {
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
