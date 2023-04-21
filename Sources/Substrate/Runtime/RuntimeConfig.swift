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
    func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo
    func hasher(metadata: Metadata) throws -> THasher
}

public extension RuntimeConfig where THasher: StaticHasher {
    func hasher(metadata: Metadata) throws -> THasher { THasher.instance }
}

public extension RuntimeConfig where TBlock.THeader: StaticBlockHeader {
    func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo {
        fatalError("Should not be called for StaticBlockHeader!")
    }
}

public struct DynamicRuntimeConfig: RuntimeConfig {
    public typealias TRuntimeVersion = AnyRuntimeVersion
    
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
        let provider = DynamicSignedExtensionsProvider<Self>(extensions: extrinsicExtensions,
                                                             version: TExtrinsicManager.version)
        return TExtrinsicManager(extensions: provider)
    }
    
    public func hasher(metadata: Metadata) throws -> AnyFixedHasher {
        let header = try blockHeaderType(metadata: metadata)
        let hashType = header.type.parameters.first { $0.name == "Hash" }?.type
        guard let hashType = hashType, let hashName = metadata.resolve(type: hashType)?.path.last else {
            throw Error.hashTypeNotFound(header: header)
        }
        guard let hasher = AnyFixedHasher(name: hashName) else {
            throw Error.unknownHashName(hashName)
        }
        return hasher
    }
    
    public func blockHeaderType(metadata: Metadata) throws -> RuntimeTypeInfo {
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
    public typealias THasher = AnyFixedHasher
    public typealias TIndex = UInt64
    public typealias TSystemProperties = AnySystemProperties
    public typealias TAccountId = AccountId32
    public typealias TAddress = Value<Void>
    public typealias TSignature = AnySignature
    public typealias TBlock = Block<AnyBlockHeader<THasher>, BlockExtrinsic<TExtrinsicManager>>
    public typealias TSignedBlock = ChainBlock<TBlock, SerializableValue>
    
    public typealias TExtrinsicManager = ExtrinsicV4Manager<Self, DynamicSignedExtensionsProvider<Self>>
    
    public typealias TExtrinsicEra = ExtrinsicEra
    public typealias TExtrinsicPayment = Value<Void>
    
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
