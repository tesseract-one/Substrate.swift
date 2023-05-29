//
//  RpcAuthorApi.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec
import JsonRPC


public struct RpcAuthorApi<S: SomeSubstrate>: RpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func pendingExtrinsics() async throws -> [BlockExtrinsic<S.RC.TExtrinsicManager>] {
        try await substrate.client.call(method: "author_pendingExtrinsics", params: Params())
    }

//    public func removeExtrinsic(
//        bytesOrHash: [ExtrinsicOrHash<S.R>],
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<[S.R.THash]>
//    ) {
//        bytesOrHash.reduce(SRpcApiResult<[Data]>.success([])) { (prev, bOrH) in
//            prev.flatMap { arr in
//                self._encode(bOrH).map { arr + [$0] }
//            }
//        }.pour(error: cb).onSuccess { array in
//            substrate.client.call(
//                method: "author_removeExtrinsic",
//                params: RpcCallParams(array),
//                timeout: timeout ?? substrate.callTimeout
//            ) { (res: RpcClientResult<[Data]>) in
//                let response = res.mapError(SubstrateRpcApiError.from).flatMap { dataArray in
//                    Result {
//                        try dataArray.map { try S.R.THash(decoding: $0) }
//                    }.mapError(SubstrateRpcApiError.from)
//                }
//                cb(response)
//            }
//        }
//    }
    
    public func submit(extrinsic bytes: Data) async throws -> S.RC.THasher.THash {
        try await substrate.client.call(method: "author_submitExtrinsic", params: Params(bytes))
    }
}

//extension SubstrateRpcAuthorApi where S.R: Session {
//    public func hasKey<K: PublicKey>(
//        publicKey: K, keyType: KeyTypeId,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<Bool>
//    ) {
//        substrate.client.call(
//            method: "author_hasKey",
//            params: RpcCallParams(publicKey.bytes, keyType.rawValue),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<Bool>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func hasSessionKeys(
//        keys: S.R.TKeys,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<Bool>
//    ) {
//        _encode(keys)
//            .pour(queue: substrate.client.responseQueue, error: cb)
//            .onSuccess { data in
//                substrate.client.call(
//                    method: "author_hasSessionKeys",
//                    params: RpcCallParams(data),
//                    timeout: timeout ?? substrate.callTimeout
//                ) { (res: RpcClientResult<Bool>) in
//                    cb(res.mapError(SubstrateRpcApiError.rpc))
//                }
//            }
//    }
//
//    public func insertKey<K: PublicKey>(
//        keyType: KeyTypeId, suri: String, publicKey: K,
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<Data>
//    ) {
//        substrate.client.call(
//            method: "author_insertKey",
//            params: RpcCallParams(keyType.rawValue, suri, publicKey.bytes),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<Data>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func rotateKeys(
//        timeout: TimeInterval? = nil,
//        _ cb: @escaping SRpcApiCallback<S.R.TKeys>
//    ) {
//        let registry = substrate.registry
//        substrate.client.call(
//            method: "author_rotateKeys",
//            params: RpcCallParams(),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<Data>) in
//            let result = res
//                .mapError(SubstrateRpcApiError.rpc)
//                .flatMap { data in
//                    Result {
//                        try S.R.TKeys(from: SCALE.default.decoder(data: data),
//                                      registry: registry)
//                    }.mapError(SubstrateRpcApiError.from)
//                }
//            cb(result)
//        }
//    }
//}

extension RpcAuthorApi where S.CL: SubscribableRpcClient {
    public func submitAndWatch(extrinsic bytes: Data) async throws -> AsyncThrowingStream<S.RC.TTransactionStatus, Error> {
        try await substrate.client.subscribe(method: "author_submitAndWatchExtrinsic",
                                             params: Params(bytes),
                                             unsubsribe: "author_unwatchExtrinsic")
    }
}

public extension RpcApiRegistry {
    var author: RpcAuthorApi<S> { get async { await getApi(RpcAuthorApi<S>.self) } }
}

//public enum ExtrinsicOrHash<R: Runtime>: ScaleDynamicEncodable {
//    case hash(R.THash)
//    case extrinsic(R.TExtrinsic)
//
//    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
//        switch self {
//        case .hash(let h): try h.encode(in: encoder, registry: registry)
//        case .extrinsic(let e): try e.encode(in: encoder, registry: registry)
//        }
//    }
//}
