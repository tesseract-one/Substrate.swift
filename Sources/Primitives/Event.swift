//
//  Event.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public protocol AnyEvent: ScaleDynamicDecodable {
    var module: String { get }
    var event: String { get }
    
    // TODO: Provide better dynamic typisation (DYNAMIC)
    var arguments: [Any] { get }
    
    static func decode(headerFrom decoder: ScaleDecoder) throws -> (module: UInt8, event: UInt8)
}

public protocol StaticEvent: AnyEvent {
    static var MODULE: String { get }
    static var EVENT: String { get }
    
    init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws
}

public protocol Event: StaticEvent {
    associatedtype Module: ModuleProtocol
}

extension AnyEvent {
    public static func decode(headerFrom decoder: ScaleDecoder) throws -> (module: UInt8, event: UInt8) {
        let module = try decoder.decode(UInt8.self)
        let event = try decoder.decode(UInt8.self)
        return (module: module, event: event)
    }
}

extension StaticEvent {
    public var module: String { return Self.MODULE }
    public var event: String { return Self.EVENT }
}

extension Event {
    public static var MODULE: String { return Module.NAME }
}

extension StaticEvent {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let header = try Self.decode(headerFrom: decoder)
        let info = try registry.info(forEvent: header)
        guard Self.MODULE == info.module && Self.EVENT == info.event else {
            throw TypeRegistryError.eventFoundWrongEvent(module: info.module,
                                                         event: info.event,
                                                         exmodule: Self.MODULE,
                                                         exevent: Self.EVENT)
        }
        try self.init(decodingDataFrom: decoder, registry: registry)
    }
}

// Dynamic event type
public struct DEvent: AnyEvent {
    public let module: String
    public let event: String
    public let arguments: [Any]
    
    public init(module: String, event: String, arguments: [DValue]) {
        self.module = module
        self.arguments = arguments
        self.event = event
    }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let header = try Self.decode(headerFrom: decoder)
        let info = try registry.info(forEvent: header)
        try self.init(module: info.module, event: info.event, decoder: decoder, registry: registry)
    }
    
    public init(module: String, event: String, decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self.module = module
        self.event = event
        
        let types = try registry.types(forEvent: event, in: module)
        self.arguments = try types.map {
            // TODO: Better decoding (DYNAMIC)
            try registry.decode(dynamic: $0, from: decoder)
        }
    }
}
