//
//  Event.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public protocol AnyEvent {
    var module: String { get }
    var event: String { get }
    var data: DValue { get }
}

public protocol Event: AnyEvent {
    associatedtype Module: ModuleProtocol
    
    static var MODULE: String { get }
    static var EVENT: String { get }
    
    init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

extension Event {
    public static var MODULE: String { return Module.NAME }
    public var module: String { return Self.MODULE }
    public var event: String { return Self.EVENT }
}

// Generic event type
public struct SEvent: AnyEvent {
    public let module: String
    public let event: String
    public let data: DValue
    
    public init(module: String, event: String, data: DValue) {
        self.module = module
        self.data = data
        self.event = event
    }
}
