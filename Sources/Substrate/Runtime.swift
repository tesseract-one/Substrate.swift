//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public protocol Runtime: System, TypeRegistrator {
    associatedtype TSignature: Signature
    associatedtype TExtrinsicExtra: SignedExtension
    
    var modules: [TypeRegistrator] { get }
}

extension Runtime {
    public func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws {
        try registry.register(type: TSignature.self, as: .type(name: "Signature"))
        for module in modules {
            try module.registerEventsCallsAndTypes(in: registry)
        }
    }
}
