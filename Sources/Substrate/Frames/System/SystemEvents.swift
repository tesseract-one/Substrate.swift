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
    public let info: DispatchInfo
}

extension SystemExtrinsicSuccessEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicSuccess" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        info = try decoder.decode()
    }
    
    public var data: DValue { DValue(info) }
}


public struct SystemExtrinsicFailedEvent<S: System> {
    /// The dispatch error.
    public let error: DispatchError
    /// The dispatch info.
    public let info: DispatchInfo
}

extension SystemExtrinsicFailedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicFailed" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        error = try decoder.decode()
        info = try decoder.decode()
    }
    
    public var data: DValue { .collection(values: [DValue(error), DValue(info)]) }
}

public struct SystemCodeUpdatedEvent<S: System> {}

extension SystemCodeUpdatedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "CodeUpdated" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {}
    
    public var data: DValue { .null }
}

public struct SystemNewAccountEvent<S: System> {
    /// Created account id.
    public let accountId: S.TAccountId
}

extension SystemNewAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "NewAccount" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
    }
    
    public var data: DValue { DValue(accountId) }
}

public struct SystemKilledAccountEvent<S: System> {
    /// Killed account id.
    public let accountId: S.TAccountId
}

extension SystemKilledAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "KilledAccount" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
    }
    
    public var data: DValue { DValue(accountId) }
}
