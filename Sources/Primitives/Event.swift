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
}

public protocol DynamicEvent: AnyEvent {
    var data: DValue { get }
}

public protocol StaticEvent: AnyEvent {
    static var MODULE: String { get }
    static var EVENT: String { get }
    
    init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

extension StaticEvent {
    public var module: String { return Self.MODULE }
    public var event: String { return Self.EVENT }
}

public protocol Event: StaticEvent {
    associatedtype Module: ModuleProtocol
}

extension Event {
    public static var MODULE: String { return Module.NAME }
}

// Dynamic event type
public struct DEvent: DynamicEvent {
    public let module: String
    public let event: String
    public let data: DValue
    
    public init(module: String, event: String, data: DValue) {
        self.module = module
        self.data = data
        self.event = event
    }
}
