//
//  SystemEvents.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct ExtrinsicSuccessEvent<S: System> {
    /// The dispatch info.
    public let info: DispatchInfo
}

extension ExtrinsicSuccessEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicSuccess" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        info = try decoder.decode()
    }
    
    public var data: DValue { DValue(info) }
}


public struct ExtrinsicFailedEvent<S: System> {
    /// The dispatch error.
    public let error: DispatchError
    /// The dispatch info.
    public let info: DispatchInfo
}

extension ExtrinsicFailedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicFailed" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        error = try decoder.decode()
        info = try decoder.decode()
    }
    
    public var data: DValue { .collection(values: [DValue(error), DValue(info)]) }
}

public struct CodeUpdatedEvent<S: System> {}

extension CodeUpdatedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "CodeUpdated" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {}
    
    public var data: DValue { .null }
}

public struct NewAccountEvent<S: System> {
    /// Created account id.
    public let accountId: S.TAccountId
}

extension NewAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "NewAccount" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
    }
    
    public var data: DValue { DValue(accountId) }
}

public struct KilledAccountEvent<S: System> {
    /// Killed account id.
    public let accountId: S.TAccountId
}

extension KilledAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "KilledAccount" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
    }
    
    public var data: DValue { DValue(accountId) }
}
