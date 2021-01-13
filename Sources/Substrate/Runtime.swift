//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public protocol Session: System {
    associatedtype TValidatorId: ScaleDynamicCodable
    associatedtype TKeys: ScaleDynamicCodable
}

public protocol Stacking: Balances {}
public protocol Contracts: Balances {}
public protocol Sudo: System {}

public protocol Runtime: System {
    associatedtype TSignature: ScaleDynamicCodable
    associatedtype TExtra: ScaleDynamicCodable
    
    var modules: [Module] { get }
    
    func register<R: TypeRegistryProtocol>(in registry: R) throws
}

extension Runtime {
    public func register<R: TypeRegistryProtocol>(in registry: R) throws {
        try registry.register(type: TSignature.self, as: .type(name: "Signature"))
        try registry.register(type: TExtra.self, as: .type(name: "Extra"))
        for module in modules {
            try module.registerEventsCallsAndTypes(in: registry)
        }
    }
}
//
//extension Session {
//    public func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws {
//        try registry.register(type: TValidatorId.self, as: .type(name: "ValidatorId"))
//        try registry.register(type: TKeys.self, as: .collection(element: .type(name: "Key")))
//    }
//}
//
//extension Balances {
//    public func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws {
//        try registry.register(type: TBalance.self, as: .type(name: "Balance"))
//    }
//}
