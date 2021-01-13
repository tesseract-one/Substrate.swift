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
    static var MODULE: Module.Type { get }
    static var EVENT: String { get }
    
    init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

extension Event {
    public var module: String { return Self.MODULE.NAME }
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
