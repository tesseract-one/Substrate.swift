//
//  SystemEvents.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct SystemExtrinsicSuccessEvent<S: System> {
    /// The dispatch info.
    public let info: DispatchInfo<S.TWeight>
}

extension SystemExtrinsicSuccessEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicSuccess" }
    
    public var arguments: [Any] { [info] }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        info = try DispatchInfo<S.TWeight>(from: decoder, registry: registry)
    }
}


public struct SystemExtrinsicFailedEvent<S: System> {
    /// The dispatch error.
    public let error: DispatchError
    /// The dispatch info.
    public let info: DispatchInfo<S.TWeight>
}

extension SystemExtrinsicFailedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicFailed" }
    
    public var arguments: [Any] { [error, info] }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        error = try decoder.decode()
        info = try DispatchInfo<S.TWeight>(from: decoder, registry: registry)
    }
}

public struct SystemCodeUpdatedEvent<S: System> {}

extension SystemCodeUpdatedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "CodeUpdated" }
    
    public var arguments: [Any] { [] }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {}
}

public struct SystemNewAccountEvent<S: System> {
    /// Created account id.
    public let accountId: S.TAccountId
}

extension SystemNewAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "NewAccount" }
    
    public var arguments: [Any] { [accountId] }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
    }
}

public struct SystemKilledAccountEvent<S: System> {
    /// Killed account id.
    public let accountId: S.TAccountId
}

extension SystemKilledAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "KilledAccount" }
    
    public var arguments: [Any] { [accountId] }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
    }
}
