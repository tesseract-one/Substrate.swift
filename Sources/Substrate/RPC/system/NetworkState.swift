//
//  NetworkState.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct NetworkState: Codable {
    public let peerId: String
    public let listenedAddresses: Array<String>
    public let externalAddresses: Array<String>
    public let connectedPeers: Dictionary<String, NetworkPeer>
    public let notConnectedPeers: Dictionary<String, NetworkNotConnectedPeer>
    public let averageDownloadPerSec: UInt64
    public let averageUploadPerSec: UInt64
    public let peerset: NetworkStatePeerset
}

public struct NetworkPeer: Codable {
    public let enabled: Bool
    public let endpoint: NetworkPeerEndpoint
    public let knownAddresses: Array<String>
    public let latestPingTime: NetworkPeerPing
    public let open: Bool
    public let versionString: String
}

public struct NetworkPeerEndpoint: Codable {
    public let listening: NetworkPeerEndpointAddr
}

public struct NetworkPeerEndpointAddr: Codable {
    public let localAddr: String
    public let sendBackAddr: String
}

public struct NetworkPeerPing: Codable {
    public let nanos: UInt64
    public let secs: UInt64
}

public struct NetworkNotConnectedPeer: Codable {
    public let knownAddresses: Array<String>
    public let latestPingTime: Optional<NetworkPeerPing>
    public let versionString: Optional<String>
}

public struct NetworkStatePeerset: Codable {
    public let messageQueue: UInt64
    public let nodes: Dictionary<String, NetworkStatePeersetInfo>
}

public struct NetworkStatePeersetInfo: Codable {
    public let connected: Bool
    public let reputation: Int32
}

public struct NetworkPeerInfo<H: Hash, BN: BlockNumberProtocol>: Codable {
    public let peerId: String
    public let roles: String
    public let protocolVersion: UInt32
    public let bestHash: H
    public let bestNumber: BN
    
    private enum CodingKeys: String, CodingKey {
        case peerId
        case roles
        case protocolVersion
        case bestHash
        case bestNumber
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        peerId = try container.decode(String.self, forKey: .peerId)
        roles = try container.decode(String.self, forKey: .roles)
        protocolVersion = try container.decode(UInt32.self, forKey: .protocolVersion)
        bestHash = try container.decode(H.self, forKey: .bestHash)
        let data = try container.decode(Data.self, forKey: .bestNumber)
        bestNumber = try BN(jsonData: data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(peerId, forKey: .peerId)
        try container.encode(roles, forKey: .roles)
        try container.encode(protocolVersion, forKey: .protocolVersion)
        try container.encode(bestHash, forKey: .bestHash)
        try container.encode(bestNumber.jsonData, forKey: .bestNumber)
    }
}
