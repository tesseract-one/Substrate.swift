//
//  RuntimeConfig.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec
import Serializable

public protocol RuntimeConfig: System {
    associatedtype TRuntimeVersion: RuntimeVersion
    
    func extrinsicManager() throws -> TExtrinsicManager
    func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo?
    func hasher(metadata: Metadata) throws -> THasher
}

public struct DynamicRuntimeConfig: RuntimeConfig {
    public typealias TRuntimeVersion = DynamicRuntimeVersion
    
    public enum Error: Swift.Error {
        case headerTypeNotFound(String)
        case hashTypeNotFound(header: RuntimeTypeInfo)
        case unknownHashName(String)
    }
    
    public let extrinsicExtensions: [DynamicExtrinsicExtension]
    public let headerPath: String
    
    public init(extrinsicExtensions: [DynamicExtrinsicExtension] = Self.allExtensions,
                headerPath: String = "sp_runtime.generic.header.Header") {
        self.extrinsicExtensions = extrinsicExtensions
        self.headerPath = headerPath
    }
    
    public func extrinsicManager() throws -> TExtrinsicManager {
        TExtrinsicManager(extensions: extrinsicExtensions)
    }
    
    public func hasher(metadata: Metadata) throws -> DynamicHasher {
        let header = try blockHeaderType(metadata: metadata)!
        let hashType = header.type.parameters.first { $0.name == "Hash" }?.type
        guard let hashType = hashType, let hashName = metadata.resolve(type: hashType)?.path.last else {
            throw Error.hashTypeNotFound(header: header)
        }
        guard let hasher = DynamicHasher(name: hashName) else {
            throw Error.unknownHashName(hashName)
        }
        return hasher
    }
    
    public func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo? {
        guard let type = metadata.resolve(type: headerPath.components(separatedBy: ".")) else {
            throw Error.headerTypeNotFound(headerPath)
        }
        return type
    }
    
    public static let allExtensions: [DynamicExtrinsicExtension] = [
        DynamicCheckSpecVersionExtension(),
        DynamicCheckTxVersionExtension(),
        DynamicCheckGenesisExtension(),
        DynamicCheckNonZeroSenderExtension(),
        DynamicCheckNonceExtension(),
        DynamicCheckMortalitySignedExtension(),
        DynamicCheckWeightExtension(),
        DynamicChargeTransactionPaymentExtension(),
        DynamicPrevalidateAttestsExtension()
    ]
}

extension DynamicRuntimeConfig: System {
    public typealias THasher = DynamicHasher
    public typealias TIndex = UInt64
    public typealias TSystemProperties = DynamicSystemProperties
    public typealias TAccountId = DynamicHash
    public typealias TAddress = Value<Void>
    public typealias TSignature = DynamicHash
    public typealias TBlock = Block<DynamicBlockHeader, BlockExtrinsic<Self>>
    public typealias TSignedBlock = ChainBlock<TBlock>
    
    public typealias TExtrinsicManager = DynamicExtrinsicManagerV4<Self>
    
    // RPC Types
    public typealias TChainType = SerializableValue
    public typealias THealth = [String: SerializableValue]
    public typealias TNetworkState = [String: SerializableValue]
    public typealias TNodeRole = SerializableValue
    public typealias TNetworkPeerInfo = [String: SerializableValue]
    public typealias TSyncState = [String: SerializableValue]
    public typealias TDispatchError = SerializableValue
    public typealias TTransactionValidityError = SerializableValue
    
    public var eventsStorageKey: any StorageKey<Data> { SystemEventsStorageKey() }
}
