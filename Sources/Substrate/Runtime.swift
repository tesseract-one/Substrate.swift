//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public protocol System {
    associatedtype Index: ScaleDynamicCodable
    associatedtype BlockNumber: ScaleDynamicCodable
    associatedtype Hash: ScaleDynamicCodable & Codable
    associatedtype Hasher: SubstratePrimitives.Hasher
    associatedtype AccountId: ScaleDynamicCodable
    associatedtype Address: ScaleDynamicCodable
    associatedtype Header: ScaleDynamicCodable
    associatedtype Extrinsic: ScaleDynamicCodable
    associatedtype AccountData: ScaleDynamicCodable
    
    func registerSystemTypes(registry: TypeRegistryProtocol) throws
}

public protocol Session: System {
    associatedtype ValidatorId: ScaleDynamicCodable
    associatedtype Keys: ScaleDynamicCodable
    
    func registerSessionTypes(registry: TypeRegistryProtocol) throws
}

public protocol Balances: System {
    associatedtype Balance: ScaleDynamicCodable
    
    func registerBalancesTypes(registry: TypeRegistryProtocol) throws
}

public protocol Stacking: Balances {}
public protocol Contracts: Balances {}
public protocol Sudo: System {}

public protocol Runtime: System {
    associatedtype Signature: ScaleDynamicCodable
    associatedtype Extra: ScaleDynamicCodable
    
    func registerRuntimeTypes(registry: TypeRegistryProtocol) throws
    func registerTypes(registry: TypeRegistryProtocol) throws
}


extension System {
    public func registerSystemTypes(registry: TypeRegistryProtocol) throws {
        try registry.register(type: Index.self, as: .type(name: "Index"))
    }
}

extension Session {
    public func registerSessionTypes(registry: TypeRegistryProtocol) throws {
        try registry.register(type: ValidatorId.self, as: .type(name: "ValidatorId"))
        try registry.register(type: Keys.self, as: .collection(element: .type(name: "Key")))
    }
}

extension Balances {
    public func registerBalancesTypes(registry: TypeRegistryProtocol) throws {
        try registry.register(type: Balance.self, as: .type(name: "Balance"))
    }
}


extension Runtime {
    public func registerRuntimeTypes(registry: TypeRegistryProtocol) throws {
        try registry.register(type: Signature.self, as: .type(name: "Signature"))
        try registry.register(type: Extra.self, as: .type(name: "Extra"))
    }
}
