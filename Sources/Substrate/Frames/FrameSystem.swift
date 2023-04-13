//
//  FrameSystem.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol System where TBlock.THeader.THasher == THasher {
    associatedtype THasher: FixedHasher
    associatedtype TIndex: UnsignedInteger & DataConvertible & Codable & ScaleRuntimeCodable
    associatedtype TSystemProperties: SystemProperties
    associatedtype TAccountId: Encodable & ValueConvertible
    associatedtype TAddress: ValueConvertible
    associatedtype TSignature: ValueConvertible
    associatedtype TBlock: AnyBlock
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
    
    public init(decodingPath decoder: ScaleDecoder, runtime: Runtime) throws {}
    public func encodePath(in encoder: ScaleCodec.ScaleEncoder, runtime: Runtime) throws {}
}
