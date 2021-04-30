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
            params: RpcCallParams(HexData(publicKey), keyType),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Bool>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func hasSessionKeys(sessionKeys: Data, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Bool>) {
        substrate.client.call(
            method: "author_hasSessionKeys",
            params: RpcCallParams(HexData(sessionKeys)),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Bool>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func insertKey(keyType: String, suri: String, publicKey: Data, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<Data>) {
        substrate.client.call(
            method: "author_insertKey",
            params: RpcCallParams(keyType, suri, HexData(publicKey)),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            cb(res.mapError(SubstrateRpcApiError.rpc).map{$0.data})
        }
    }
    
    public func pendingExtrinsics(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<[S.R.TExtrinsic]>) {
        substrate.client.call(
            method: "author_pendingExtrinsics",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[HexData]>) in
            let response = res.mapError(SubstrateRpcApiError.from).flatMap { dataArray in
                Result {
                    try dataArray.map { data in
                        try S.R.TExtrinsic(data: data.data, registry: substrate.registry)
                    }
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(response)
        }
    }

    public func removeExtrinsic<H: Hash>(bytesOrHash: [ExtrinsicOrHash<H>], timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<[S.R.THash]>) {
        var hexArray = [HexData]()
        for boh in bytesOrHash {
            switch boh {
            case .hash(let hash):
                guard let data = _encode(value: hash, cb) else { return }
                hexArray.append(HexData(data))
            case .extrinsic(let data):
                hexArray.append(HexData(data))
            }
        }
        substrate.client.call(
            method: "author_removeExtrinsic",
            params: RpcCallParams(hexArray),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<[HexData]>) in
            let response = res.mapError(SubstrateRpcApiError.from).flatMap { dataArray in
                Result {
                    try dataArray.map { try S.R.THash(decoding: $0.data) }
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
        ) { (res: RpcClientResult<HexData>) in
            cb(res.mapError(SubstrateRpcApiError.rpc).map{$0.data})
        }
    }
    
    public func submit<E: ExtrinsicProtocol>(
        extrinsic: E, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THash>
    ) {
        guard let data = _encode(value: extrinsic, cb) else { return }
        substrate.client.call(
            method: "author_submitExtrinsic",
            params: RpcCallParams(HexData(data)),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<HexData>) in
            let response = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result { try S.R.THash(decoding: data.data) }.mapError(SubstrateRpcApiError.from)
            }
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
