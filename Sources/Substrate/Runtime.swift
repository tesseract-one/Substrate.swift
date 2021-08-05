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
    var supportedSpecVersions: Range<UInt32> { get }
    
    var modules: [ModuleBase] { get }
}

extension Runtime {
    public static var NAME: String { Self.id }
    
    public func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: R) throws {
        for module in modules {
            try module.registerEventsCallsAndTypes(in: registry)
        }
    }
}
