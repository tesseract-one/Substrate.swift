//
//  RpcOffchainApi.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public struct SubstrateRpcOffchainApi<S: SubstrateProtocol>: SubstrateRpcApi {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func localStorageGet(
        kind: StorageKind, key: Data,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<Optional<Data>>
    ) {
        substrate.client.call(
            method: "offchain_localStorageGet",
            params: RpcCallParams(kind, key),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Optional<Data>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func localStorageSet(
        kind: StorageKind,
        key: Data, value: Data,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<DNull>
    ) {
        substrate.client.call(
            method: "offchain_localStorageSet",
            params: RpcCallParams(kind, key, value),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<DNull>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry {
    public var offchain: SubstrateRpcOffchainApi<S> { getRpcApi(SubstrateRpcOffchainApi<S>.self) }
}

public enum StorageKind: Equatable, Codable {
    case persistent
    case local
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "PERSISTENT": self = .persistent
        case "LOCAL": self = .local
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown case \(value)")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .persistent: try container.encode("PERSISTENT")
        case .local: try container.encode("LOCAL")
        }
    }
}
