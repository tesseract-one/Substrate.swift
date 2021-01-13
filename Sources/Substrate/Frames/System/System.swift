//
//  System.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public protocol System {
    associatedtype TIndex: ScaleDynamicCodable
    associatedtype TBlockNumber: ScaleDynamicCodable
    associatedtype THash: Hash
    associatedtype THasher: Hasher
    associatedtype TAccountId: ScaleDynamicCodable
    associatedtype TAddress: ScaleDynamicCodable
    associatedtype THeader: ScaleDynamicCodable
    //associatedtype TExtrinsic: ScaleDynamicCodable
    associatedtype TAccountData: ScaleDynamicCodable
}

open class SystemModule<S: System>: Module {
    public static var NAME: String { "System" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        // System types
        try registry.register(type: S.TIndex.self, as: .type(name: "Index"))
        try registry.register(type: S.TBlockNumber.self, as: .type(name: "BlockNumber"))
        try registry.register(type: S.THash.self, as: .type(name: "Hash"))
        try registry.register(type: S.TAccountId.self, as: .type(name: "AccountId"))
        try registry.register(type: S.TAddress.self, as: .type(name: "Address"))
        try registry.register(type: S.THeader.self, as: .type(name: "Header"))
        try registry.register(type: S.TAccountData.self, as: .type(name: "AccountData"))
        // System calls
        try registry.register(call: SetCodeCall<S>.self)
        try registry.register(call: SetCodeWithoutChecksCall<S>.self)
        // System events
        try registry.register(event: ExtrinsicSuccessEvent<S>.self)
        try registry.register(event: ExtrinsicFailedEvent<S>.self)
        try registry.register(event: CodeUpdatedEvent<S>.self)
        try registry.register(event: NewAccountEvent<S>.self)
        try registry.register(event: KilledAccountEvent<S>.self)
    }
}
