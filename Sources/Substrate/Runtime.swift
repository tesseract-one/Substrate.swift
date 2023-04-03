//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec
import Serializable

public protocol Runtime: System {
    associatedtype TRuntimeVersion: RuntimeVersion
    
    func extrinsicManager() throws -> TExtrinsicManager
}

public struct DynamicRuntime: Runtime {
    public typealias TRuntimeVersion = DynamicRuntimeVersion
    public init() {}
    
    public func extrinsicManager() throws -> TExtrinsicManager {
        TExtrinsicManager(extensions: [
            DynamicCheckSpecVersionExtension(),
            DynamicCheckTxVersionExtension(),
            DynamicCheckGenesisExtension(),
            DynamicCheckNonZeroSenderExtension(),
            DynamicCheckNonceExtension(),
            DynamicCheckMortalitySignedExtension(),
            DynamicCheckWeightExtension(),
            DynamicChargeTransactionPaymentExtension(),
            DynamicPrevalidateAttestsExtension()
        ])
    }
}

extension DynamicRuntime: System {
    public typealias THash = DynamicHash
    public typealias TIndex = UInt64
    public typealias TBlockNumber = UInt256
    public typealias TSystemProperties = DynamicSystemProperties
    public typealias TAccountId = DynamicHash
    
    public typealias TExtrinsicManager = DynamicExtrinsicManagerV4<Self>
    
    // RPC Types
    public typealias TChainType = SerializableValue
    public typealias THealth = [String: SerializableValue]
    public typealias TNetworkState = [String: SerializableValue]
    public typealias TNodeRole = SerializableValue
    public typealias TNetworkPeerInfo = [String: SerializableValue]
    public typealias TSyncState = [String: SerializableValue]
    
    public typealias TAddress = Value<Void>
    public typealias TSignature = DynamicHash
    public typealias TDispatchError = SerializableValue
    public typealias TTransactionValidityError = SerializableValue
    
    public var eventsStorageKey: any StorageKey<Data> {
        SystemEventsStorageKey()
    }
}
