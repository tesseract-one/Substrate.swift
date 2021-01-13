//
//  Balances.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public protocol Balances: System {
    associatedtype TBalance: ScaleDynamicCodable & CompactCodable
}

open class BalancesModule<B: Balances>: ModuleProtocol {
    public typealias Frame = B
    
    public static var NAME: String { "Balances" }
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        try registry.register(type: B.TBalance.self, as: .type(name: "Balance"))
        try registry.register(type: B.TBalance.self, as: .type(name: "BalanceOf"))
        try registry.register(type: SCompact<B.TBalance>.self, as: .compact(type: .type(name: "Balance")))
        try registry.register(type: SCompact<B.TBalance>.self, as: .compact(type: .type(name: "BalanceOf")))
        try registry.register(call: TransferCall<B>.self)
        try registry.register(event: TransferEvent<B>.self)
    }
}

