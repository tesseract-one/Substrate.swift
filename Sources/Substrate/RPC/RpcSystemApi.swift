//
//  RpcSystemApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC

public struct RpcSystemApi<S: AnySubstrate>: RpcApi where S.RT: System {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func accountNextIndex(id: S.RT.TAccountId) async throws -> S.RT.TIndex {
        try await substrate.client.call(
            method: "system_accountNextIndex",
            params: Params(id),
            HexOrNumber<S.RT.TIndex>.self
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

    public func chainType() async throws -> S.RT.TChainType {
        try await substrate.client.call(method: "system_chainType", params: Params())
    }
//
//    public func dryRun(
//        extrinsic: S.R.TExtrinsic, at hash: S.R.THash?,
//        timeout: TimeInterval? = nil,
//        cb: @escaping SRpcApiCallback<ApplyExtrinsicResult>
//    ) {
//        _encode(extrinsic)
//            .pour(error: cb)
//            .onSuccess { data in
//                substrate.client.call(
//                    method: "system_dryRun",
//                    params: RpcCallParams(data, hash),
//                    timeout: timeout ?? substrate.callTimeout
//                ) { (res: RpcClientResult<ApplyExtrinsicResult>) in
//                    cb(res.mapError(SubstrateRpcApiError.rpc))
//                }
//            }
//    }
//
    public func health() async throws -> S.RT.THealth {
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

    public func networkState() async throws -> S.RT.TNetworkState {
        try await substrate.client.call(method: "system_networkState", params: Params())
    }

    public func nodeRoles() async throws -> [S.RT.TNodeRole] {
        try await substrate.client.call(method: "system_nodeRoles", params: Params())
    }

    public func peers() async throws -> [S.RT.TNetworkPeerInfo] {
        try await substrate.client.call(method: "system_peers", params: Params())
    }

    public func properties() async throws -> S.RT.TSystemProperties {
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

    public func syncState() async throws -> S.RT.TSyncState {
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
    public static func properties(with client: CallableClient) async throws -> S.RT.TSystemProperties {
        try await client.call(method: "system_properties", params: Params())
    }
}

extension RpcApiRegistry where S.RT: System {
    public var system: RpcSystemApi<S> { get async { await getRpcApi(RpcSystemApi<S>.self) } }
}
//
//public typealias DispatchOutcome = RpcResult<DNull, DispatchError>
//public typealias ApplyExtrinsicResult = RpcResult<DispatchOutcome, TransactionValidityError>
