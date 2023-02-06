//
//  FrameSystem.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol System {
    associatedtype THash: Hash
    associatedtype TIndex: UnsignedInteger & DataConvertible & Codable & RegistryScaleCodable
    associatedtype TBlockNumber: UnsignedInteger & DataConvertible
    associatedtype TSystemProperties: SystemProperties
    associatedtype TAccountId: Encodable & ValueConvertible
    associatedtype TAddress: ValueConvertible
    associatedtype TSignature: ValueConvertible
    
    // Helpers
    associatedtype TExtrinsicManager: ExtrinsicManager<Self>
    
    // RPC structures
    associatedtype TChainType: Decodable
    associatedtype THealth: Decodable
    associatedtype TNetworkState: Decodable
    associatedtype TNodeRole: Decodable
    associatedtype TNetworkPeerInfo: Decodable
    associatedtype TSyncState: Decodable
    associatedtype TDispatchError: Decodable
    associatedtype TTransactionValidityError: Decodable
}

