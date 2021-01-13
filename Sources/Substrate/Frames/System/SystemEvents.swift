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
    // dynamic type of value
    private let type: DType
}

extension SystemExtrinsicSuccessEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicSuccess" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        info = try decoder.decode()
        type = try registry.type(of: DispatchInfo.self)
    }
    
    public var data: DValue { .native(type: type, value: info) }
}


public struct SystemExtrinsicFailedEvent<S: System> {
    /// The dispatch error.
    public let error: DispatchError
    /// The dispatch info.
    public let info: DispatchInfo
    /// dynamic types
    private let types: (error: DType, info: DType)
}

extension SystemExtrinsicFailedEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "ExtrinsicFailed" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        error = try decoder.decode()
        info = try decoder.decode()
        types = try (error: registry.type(of: DispatchError.self), info: registry.type(of: DispatchInfo.self))
    }
    
    public var data: DValue {
        .collection(values: [
            .native(type: types.error, value: error),
            .native(type: types.info, value: info)
        ])
    }
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
    /// dynamic type
    private let type: DType
}

extension SystemNewAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "NewAccount" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
        type = try registry.type(of: S.TAccountId.self)
    }
    
    public var data: DValue { .native(type: type, value: accountId) }
}

public struct SystemKilledAccountEvent<S: System> {
    /// Killed account id.
    public let accountId: S.TAccountId
    /// dynamic type
    private let type: DType
}

extension SystemKilledAccountEvent: Event {
    public typealias Module = SystemModule<S>
    
    public static var EVENT: String { "KilledAccount" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        accountId = try S.TAccountId(from: decoder, registry: registry)
        type = try registry.type(of: S.TAccountId.self)
    }
    
    public var data: DValue { .native(type: type, value: accountId) }
}
