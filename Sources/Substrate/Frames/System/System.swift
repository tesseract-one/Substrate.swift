//
//  System.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public protocol System: BaseFrame {
    associatedtype TIndex: ScaleDynamicCodable & CompactCodable & SDefault & Codable
    associatedtype TBlockNumber: BlockNumberProtocol
    associatedtype THash: Hash
    associatedtype THasher: Hasher
    associatedtype TAccountId: PublicKey & Hashable & SDefault
    associatedtype TAddress: Address & SDefault
    associatedtype THeader: ScaleDynamicCodable & Codable
    associatedtype TExtrinsic: ExtrinsicProtocol
    associatedtype TAccountData: ScaleDynamicCodable
}

open class SystemModule<S: System>: ModuleProtocol {
    public typealias Frame = S
    
    public static var NAME: String { "System" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        // System types
        try registry.register(type: S.TIndex.self, as: .type(name: "Index"))
        try registry.register(type: S.TBlockNumber.self, as: .type(name: "BlockNumber"))
        try registry.register(type: S.THash.self, as: .type(name: "Hash"))
        try registry.register(type: S.TAccountId.self, as: .type(name: "AccountId"))
        try registry.register(type: S.TAddress.self, as: .type(name: "Address"))
        try registry.register(type: S.TAddress.self, as: .type(name: "LookupSource"))
        try registry.register(type: S.THeader.self, as: .type(name: "Header"))
        try registry.register(type: S.TAccountData.self, as: .type(name: "AccountData"))
        try registry.register(type: S.TExtrinsic.self, as: .type(name: "Extrinsic"))
        try registry.register(type: Origin<S.TAccountId>.self, as: .type(name: "Origin"))
        try registry.register(type: RuntimeDbWeight<S.TWeight>.self, as: .type(name: "RuntimeDbWeight"))
        try registry.register(type: RefCount.self, as: .type(name: "RefCount"))
        try registry.register(type: SCompact<RefCount>.self, as: .compact(type: .type(name: "RefCount")))
        // System calls
        try registry.register(call: SystemSetCodeCall<S>.self)
        try registry.register(call: SystemSetCodeWithoutChecksCall<S>.self)
        // System events
        try registry.register(event: SystemExtrinsicSuccessEvent<S>.self)
        try registry.register(event: SystemExtrinsicFailedEvent<S>.self)
        try registry.register(event: SystemCodeUpdatedEvent<S>.self)
        try registry.register(event: SystemNewAccountEvent<S>.self)
        try registry.register(event: SystemKilledAccountEvent<S>.self)
    }
}


public struct RuntimeDbWeight<Weight: WeightProtocol>: ScaleDynamicCodable {
    public let read: Weight
    public let write: Weight
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        read = try Weight(from: decoder, registry: registry)
        write = try Weight(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try read.encode(in: encoder, registry: registry)
        try write.encode(in: encoder, registry: registry)
    }
}
