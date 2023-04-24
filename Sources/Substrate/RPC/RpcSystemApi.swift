//
//  RpcSystemApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC
import Serializable

public struct RpcSystemApi<S: SomeSubstrate>: RpcApi where S.RC: System {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func accountNextIndex(id: S.RC.TAccountId) async throws -> S.RC.TIndex {
        try await substrate.client.call(
            method: "system_accountNextIndex",
            params: Params(id),
            HexOrNumber<S.RC.TIndex>.self
        ).value
    }

    public func addLogFilter(directives: String) async throws {
        let _: Nil = try await substrate.client.call(
            method: "system_addLogFilter",
            params: Params(directives)
        )
    }
    
    public func addReservedPeer(peer: String) async throws -> String {
        try await substrate.client.call(method: "system_addReservedPeer", params: Params(peer))
    }

    public func chain() async throws -> String {
        try await substrate.client.call(method: "system_chain", params: Params())
    }

    public func chainType() async throws -> S.RC.TChainType {
        try await substrate.client.call(method: "system_chainType", params: Params())
    }
    
    public func hasDryRun() async throws -> Bool {
        try await substrate.runtime.rpcMethods.contains("system_dryRun")
    }

    public func dryRun<C: Call>(
        extrinsic: SignedExtrinsic<C, S.RC.TExtrinsicManager>, at hash: S.RC.THasher.THash?
    ) async throws -> RpcResult<RpcResult<Nil, S.RC.TDispatchError>, S.RC.TTransactionValidityError> {
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        return try await substrate.client.call(method: "system_dryRun", params: Params(encoder.output, hash))
    }

    public func health() async throws -> S.RC.THealth {
        try await substrate.client.call(method: "system_health", params: Params())
    }

    public func localListenAddresses() async throws -> [String] {
        try await substrate.client.call(
            method: "system_localListenAddresses",
            params: Params()
        )
    }

    public func localPeerId() async throws -> String {
        try await substrate.client.call(method: "system_localPeerId", params: Params())
    }

    public func name() async throws -> String {
        try await substrate.client.call(method: "system_name", params: Params())
    }

    public func networkState() async throws -> S.RC.TNetworkState {
        try await substrate.client.call(method: "system_networkState", params: Params())
    }

    public func nodeRoles() async throws -> [S.RC.TNodeRole] {
        try await substrate.client.call(method: "system_nodeRoles", params: Params())
    }

    public func peers() async throws -> [S.RC.TNetworkPeerInfo] {
        try await substrate.client.call(method: "system_peers", params: Params())
    }

    public func properties() async throws -> S.RC.TSystemProperties {
        try await Self.properties(with: substrate.client)
    }

    public func removeReservedPeer(peer: String) async throws -> String {
        try await substrate.client.call(
            method: "system_removeReservedPeer",
            params: Params(peer)
        )
    }

    public func reservedPeers() async throws -> [String] {
        try await substrate.client.call(
            method: "system_reservedPeers",
            params: Params()
        )
    }

    public func resetLogFilter() async throws {
        let _: Nil = try await substrate.client.call(
            method: "system_resetLogFilter",
            params: Params()
        )
    }

    public func syncState() async throws -> S.RC.TSyncState {
        try await substrate.client.call(
            method: "system_syncState",
            params: Params()
        )
    }

    public func version() async throws -> String {
        try await substrate.client.call(method: "system_version", params: Params())
    }
}

extension RpcSystemApi { //Static calls
    public static func properties(with client: CallableClient) async throws -> S.RC.TSystemProperties {
        try await client.call(method: "system_properties", params: Params())
    }
}

extension RpcApiRegistry where S.RC: System {
    public var system: RpcSystemApi<S> { get async { await getApi(RpcSystemApi<S>.self) } }
}
