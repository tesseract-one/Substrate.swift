//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public protocol Runtime: System, ModuleBase, DynamicTypeId {
    associatedtype TSignature: Signature
    associatedtype TExtrinsicExtra: SignedExtension
    
    var modules: [ModuleBase] { get }
}

extension Runtime {
    public static var NAME: String { Self.id }
    
    public func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws {
        try registry.register(type: TSignature.self, as: .type(name: "Signature"))
        for module in modules {
            try module.registerEventsCallsAndTypes(in: registry)
        }
    }
}
