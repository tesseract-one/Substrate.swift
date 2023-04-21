//
//  RpcChainApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import JsonRPC

public struct RpcChainApi<S: SomeSubstrate>: RpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func block(at hash: S.RC.THasher.THash? = nil) async throws -> S.RC.TSignedBlock {
        try await substrate.client.call(method: "chain_getBlock", params: Params(hash))
    }
    
    public func header(at hash: S.RC.THasher.THash? = nil) async throws -> S.RC.TBlock.THeader? {
        try await substrate.client.call(method: "chain_getHeader", params: Params(hash))
    }
    
    public func finalizedHead() async throws -> S.RC.THasher.THash {
        try await substrate.client.call(method: "chain_getFinalizedHead", params: Params())
    }
    
    public func blockHash(block: S.RC.TBlock.THeader.TNumber?) async throws -> S.RC.THasher.THash {
        try await Self.blockHash(block: block, client: substrate.client)
    }
}

extension RpcChainApi where S.CL: SubscribableClient {
    public func subscribeAllHeads() async throws -> AsyncThrowingStream<S.RC.TBlock.THeader, Error> {
        try await substrate.client.subscribe(method: "chain_subscribeAllHeads",
                                             params: Params(),
                                             unsubsribe: "chain_unsubscribeAllHeads")
    }
    
    public func subscribeFinalizedHeads() async throws -> AsyncThrowingStream<S.RC.TBlock.THeader, Error> {
        try await substrate.client.subscribe(method: "chain_subscribeFinalizedHeads",
                                             params: Params(),
                                             unsubsribe: "chain_unsubscribeFinalizedHeads")
    }
    
    public func subscribeNewHeads() async throws -> AsyncThrowingStream<S.RC.TBlock.THeader, Error> {
        try await substrate.client.subscribe(method: "chain_unsubscribeNewHeads",
                                             params: Params(),
                                             unsubsribe: "chain_unsubscribeNewHeads")
    }
}

extension RpcChainApi { // Static
    public static func blockHash(
        block: S.RC.TBlock.THeader.TNumber?, client: CallableClient
    ) async throws -> S.RC.THasher.THash {
        try await client.call(method: "chain_getBlockHash", params: Params(block.map(UIntHex.init)))
    }
}

extension RpcApiRegistry {
    public var chain: RpcChainApi<S> { get async { await getApi(RpcChainApi<S>.self) } }
}
