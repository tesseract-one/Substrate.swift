//
//  FrameSystem.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol System {
    associatedtype THasher: FixedHasher
    associatedtype TIndex: UnsignedInteger & DataConvertible & CompactCodable & Codable & ScaleRuntimeCodable
    associatedtype TAccountId: AccountId
    associatedtype TAddress: Address where TAddress.TAccountId == TAccountId
    associatedtype TSignature: Signature
    associatedtype TBlock: SomeBlock where TBlock.THeader.THasher == THasher
    associatedtype TSignedBlock: SomeChainBlock<TBlock>
    
    associatedtype TExtrinsicEra: SomeExtrinsicEra
    associatedtype TExtrinsicPayment: ValueRepresentable & Default
    
    // Helpers
    associatedtype TExtrinsicManager: ExtrinsicManager<Self>
    
    // RPC structures
    associatedtype TSystemProperties: SystemProperties
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
