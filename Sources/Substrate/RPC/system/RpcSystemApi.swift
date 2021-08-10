//
//  RpcSystemApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc
import ScaleCodec

public struct SubstrateRpcSystemApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func accountNextIndex(
        accountId: S.R.TAccountId,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<S.R.TIndex>
    ) {
        substrate.client.call(
            method: "system_accountNextIndex",
            params: RpcCallParams(accountId.bytes),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<S.R.TIndex>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func addLogFilter(
        directives: String,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<DNull>
    ) {
        substrate.client.call(
            method: "system_addLogFilter",
            params: RpcCallParams(directives),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<DNull>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func addReservedPeer(
        peer: String,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<String>
    ) {
        substrate.client.call(
            method: "system_addReservedPeer",
            params: RpcCallParams(peer),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<String>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func chain(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<String>
    ) {
        substrate.client.call(
            method: "system_chain",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<String>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func chainType(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<ChainType>
    ) {
        substrate.client.call(
            method: "system_chainType",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ChainType>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func dryRun(
        extrinsic: S.R.TExtrinsic, at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<ApplyExtrinsicResult>
    ) {
        _encode(extrinsic)
            .pour(error: cb)
            .onSuccess { data in
                substrate.client.call(
                    method: "system_dryRun",
                    params: RpcCallParams(data, hash),
                    timeout: timeout ?? substrate.callTimeout
                ) { (res: RpcClientResult<ApplyExtrinsicResult>) in
                    cb(res.mapError(SubstrateRpcApiError.rpc))
                }
            }
    }
    
    public func health(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Health>
    ) {
        substrate.client.call(
            method: "system_health",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Health>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func localListenAddresses(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Array<String>>
    ) {
        substrate.client.call(
            method: "system_localListenAddresses",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Array<String>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func localPeerId(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<String>
    ) {
        substrate.client.call(
            method: "system_localPeerId",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<String>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func name(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<String>
    ) {
        substrate.client.call(
            method: "system_name",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<String>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func networkState(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<NetworkState>
    ) {
        substrate.client.call(
            method: "system_networkState",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<NetworkState>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func nodeRoles(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Array<NodeRole>>
    ) {
        substrate.client.call(
            method: "system_nodeRoles",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Array<NodeRole>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func peers(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Array<NetworkPeerInfo<S.R.THash, S.R.TBlockNumber>>>
    ) {
        substrate.client.call(
            method: "system_peers",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Array<NetworkPeerInfo<S.R.THash, S.R.TBlockNumber>>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func properties(timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<SystemProperties>) {
        Self.properties(client: substrate.client, timeout: timeout ?? substrate.callTimeout, cb)
    }
    
    public func removeReservedPeer(
        peerId: String,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<String>
    ) {
        substrate.client.call(
            method: "system_removeReservedPeer",
            params: RpcCallParams(peerId),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<String>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func reservedPeers(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<Array<String>>
    ) {
        substrate.client.call(
            method: "system_reservedPeers",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Array<String>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func resetLogFilter(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<DNull>
    ) {
        substrate.client.call(
            method: "system_resetLogFilter",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<DNull>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func syncState(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<SyncState<S.R.TBlockNumber>>
    ) {
        substrate.client.call(
            method: "system_syncState",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<SyncState<S.R.TBlockNumber>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func version(
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<String>
    ) {
        substrate.client.call(
            method: "system_version",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<String>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcSystemApi { //Static calls
    public static func properties(
        client: RpcClient, timeout: TimeInterval,
        _ cb: @escaping SRpcApiCallback<SystemProperties>
    ) {
        client.call(
            method: "system_properties",
            params: RpcCallParams(),
            timeout: timeout
        ) { (res: RpcClientResult<SystemProperties>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var system: SubstrateRpcSystemApi<S> { getRpcApi(SubstrateRpcSystemApi<S>.self) }
}

public typealias DispatchOutcome = RpcResult<DNull, DispatchError>
public typealias ApplyExtrinsicResult = RpcResult<DispatchOutcome, TransactionValidityError>
