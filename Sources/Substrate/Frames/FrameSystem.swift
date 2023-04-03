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
    associatedtype TBlock: Block
    associatedtype TSignedBlock: AnyChainBlock<TBlock>
    
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
    
    var eventsStorageKey: any StorageKey<Data> { get }
}

public struct SystemEventsStorageKey: StaticStorageKey {
    public typealias TValue = Data
    
    public static var name: String = "Events"
    public static var pallet: String = "System"
    
    public init() {}
    
    public init(decodingPath decoder: ScaleDecoder, registry: Registry) throws {}
    public func encodePath(in encoder: ScaleCodec.ScaleEncoder, registry: Registry) throws {}
}
