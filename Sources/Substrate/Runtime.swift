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

public protocol Runtime: System, TypeRegistrator {
    associatedtype TSignature: ScaleDynamicCodable
    associatedtype TExtra: ScaleDynamicCodable
    
    var modules: [TypeRegistrator] { get }
}

extension Runtime {
    public func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws {
        try registry.register(type: TSignature.self, as: .type(name: "Signature"))
        try registry.register(type: TExtra.self, as: .type(name: "Extra"))
        for module in modules {
            try module.registerEventsCallsAndTypes(in: registry)
        }
    }
}
