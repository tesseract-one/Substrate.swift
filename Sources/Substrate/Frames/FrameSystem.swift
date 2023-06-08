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
    associatedtype TBlockEvents: SomeBlockEvents
    associatedtype TDispatchError: SomeDispatchError
    associatedtype TDispatchInfo: ScaleRuntimeDynamicDecodable
    associatedtype TFeeDetails: ScaleRuntimeDynamicDecodable
    associatedtype TTransactionStatus: SomeTransactionStatus<TBlock.THeader.THasher.THash>
   
    
    // Helpers
    associatedtype TExtrinsicFailureEvent: SomeExtrinsicFailureEvent<TDispatchError>
    associatedtype TExtrinsicManager: ExtrinsicManager<Self>
    
    // RPC structures
    associatedtype TSystemProperties: SystemProperties
    associatedtype TChainType: Decodable
    associatedtype THealth: Decodable
    associatedtype TNetworkState: Decodable
    associatedtype TNodeRole: Decodable
    associatedtype TNetworkPeerInfo: Decodable
    associatedtype TSyncState: Decodable
    associatedtype TTransactionValidityError: Decodable
    
    func eventsStorageKey(metadata: Metadata) throws -> any StorageKey<TBlockEvents>
}

public protocol SomeExtrinsicFailureEvent<Err>: StaticEvent {
    associatedtype Err: SomeDispatchError
    func asError() throws -> Err
}

public struct ExtrinsicFailureEvent<Err: SomeDispatchError>: SomeExtrinsicFailureEvent {
    public typealias Err = Err
    public static var pallet: String { "System" }
    public static var name: String { "ExtrinsicFailure" }
    
    public let error: Value<RuntimeTypeId>
    
    public init(params: [Value<RuntimeTypeId>]) throws {
        guard params.count == 1, let err = params.first else {
            throw ValueInitializableError<RuntimeTypeId>.wrongValuesCount(in: .sequence(params),
                                                                          expected: 1,
                                                                          for: Self.name)
        }
        self.error = err
    }
    
    public func asError() throws -> Err {
        try Err(value: error)
    }
}


public struct SystemEventsStorageKey<BE: SomeBlockEvents>: StaticStorageKey {
    public typealias TValue = BE
    
    public static var name: String { "Events" }
    public static var pallet: String { "System" }
    
    public init() {}
    
    public init(decodingPath decoder: ScaleDecoder, runtime: Runtime) throws {}
    public func encodePath(in encoder: ScaleCodec.ScaleEncoder, runtime: Runtime) throws {}
}
