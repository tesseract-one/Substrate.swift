//
//  Sudo.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation
import ScaleCodec

public protocol Sudo: System {}

open class SudoModule<S: Sudo>: ModuleProtocol {
    public typealias Frame = S
    
    public static var NAME: String { "Sudo" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        try registry.register(type: Weight.self, as: .type(name: "Weight"))
        try registry.register(call: SudoCall<S>.self)
        try registry.register(call: SudoUncheckedWeightCall<S>.self)
    }
}

public typealias Weight = UInt64

/// Execute a transaction with sudo permissions.
public struct SudoCall<S: Sudo> {
    /// Encoded transaction.
    public let call: AnyCall
}

extension SudoCall: Call {
    public typealias Module = SudoModule<S>
    
    public static var FUNCTION: String { "Sudo" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        call = try registry.decodeCall(from: decoder)
    }
    
    public var params: [ScaleDynamicCodable] {
        [DCall(module: call.module, function: call.function, params: call.params)]
    }
}

/// Execute a transaction with sudo permissions without checking the call weight.
public struct SudoUncheckedWeightCall<S: Sudo> {
    /// Encoded transaction.
    public let call: AnyCall
    /// Call weight.
    ///
    /// This argument is actually unused in runtime, you can pass any value of
    /// `Weight` type when using this call.
    public let weight: Weight
}

extension SudoUncheckedWeightCall: Call {
    public typealias Module = SudoModule<S>
    
    public static var FUNCTION: String { "SudoUncheckedWeight" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        call = try registry.decodeCall(from: decoder)
        weight = try decoder.decode()
    }
    
    public var params: [ScaleDynamicCodable] {
        [DCall(module: call.module, function: call.function, params: call.params), weight]
    }
}
