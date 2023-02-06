//
//  RpcChainApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import JsonRPC

public struct RpcChainApi<S: AnySubstrate>: RpcApi {
    public weak var substrate: S!
    
//    public typealias ChainBlock<Extrinsic> = SignedBlock<Block<S.R.THeader, Extrinsic>>
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
//    public func getBlock(hash: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<ChainBlock<S.R.TExtrinsic>>) {
//        substrate.client.call(
//            method: "chain_getBlock",
//            params: RpcCallParams(hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<ChainBlock<Data>>) in
//            let response = res.mapError(SubstrateRpcApiError.rpc).flatMap { cbd in
//                Result {
//                    ChainBlock<S.R.TExtrinsic>(
//                        block: Block(
//                            header: cbd.block.header,
//                            extrinsics: try cbd.block.extrinsics.map {
//                                try S.R.TExtrinsic(from: SCALE.default.decoder(data: $0),
//                                                   registry: self.substrate.registry)
//                            }
//                        ),
//                        justification: cbd.justification
//                    )
//                }.mapError(SubstrateRpcApiError.from)
//            }
//            cb(response)
//        }
//    }
//
    public func blockHash(block: S.RT.TBlockNumber?) async throws -> S.RT.THash {
        try await Self.blockHash(block: block, client: substrate.client)
    }
//
//    public func getFinalizedHead(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THash>) {
//        substrate.client.call(
//            method: "chain_getFinalizedHead",
//            params: RpcCallParams(),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<S.R.THash>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func getHeader(hash: S.R.THash?, timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THeader>) {
//        substrate.client.call(
//            method: "chain_getHeader",
//            params: RpcCallParams(hash),
//            timeout: timeout ?? substrate.callTimeout
//        ) { (res: RpcClientResult<S.R.THeader>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
}
//
//extension SubstrateRpcChainApi where S.C: SubscribableRpcClient {
//    public func subscribeAllHeads(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THeader>) -> RpcSubscription {
//        return substrate.client.subscribe(
//            method: "chain_subscribeAllHeads",
//            params: RpcCallParams(),
//            unsubscribe: "chain_unsubscribeAllHeads"
//        ) { (res: RpcClientResult<S.R.THeader>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func subscribeFinalizedHeads(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THeader>) -> RpcSubscription {
//        return substrate.client.subscribe(
//            method: "chain_subscribeFinalizedHeads",
//            params: RpcCallParams(),
//            unsubscribe: "chain_unsubscribeFinalizedHeads"
//        ) { (res: RpcClientResult<S.R.THeader>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//
//    public func subscribeNewHeads(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<S.R.THeader>) -> RpcSubscription {
//        return substrate.client.subscribe(
//            method: "chain_subscribeNewHeads",
//            params: RpcCallParams(),
//            unsubscribe: "chain_unsubscribeNewHeads"
//        ) { (res: RpcClientResult<S.R.THeader>) in
//            cb(res.mapError(SubstrateRpcApiError.rpc))
//        }
//    }
//}

extension RpcChainApi { // Static
    public static func blockHash(
        block: S.RT.TBlockNumber?, client: CallableClient
    ) async throws -> S.RT.THash {
        try await client.call(method: "chain_getBlockHash", params: Params(block.map(UIntHex.init)))
    }
}

extension RpcApiRegistry {
    public var chain: RpcChainApi<S> { get async { await getRpcApi(RpcChainApi<S>.self) } }
}
