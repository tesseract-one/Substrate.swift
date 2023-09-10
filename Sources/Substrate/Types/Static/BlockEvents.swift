//
//  BlockEvents.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct BlockEvents<ER: SomeEventRecord>: SomeBlockEvents,
                                                CustomStringConvertible {
    public typealias ER = ER
    
    public let events: [ER]
    
    public init(events: [ER]) {
        self.events = events
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: TypeDefinition,
                                       runtime: Runtime) throws
    {
        let record = try Self.recordType(events: type)
        let events = try Array<ER>(from: &decoder) { decoder in
            try runtime.decode(from: &decoder) { record }
        }
        self.init(events: events)
    }
    
    public func events(extrinsic index: UInt32) -> [ER] {
        events.filter { $0.extrinsicIndex.map{$0 == index} ?? false }
    }
    
    public var description: String {
        events.description
    }
    
    public static func recordType(events type: TypeDefinition) throws -> TypeDefinition {
        switch type.flatten().definition {
        case .sequence(of: let record): return *record
        default:
            throw TypeError.wrongType(for: Self.self, type: type,
                                      reason: "Not a sequence", .get())
        }
    }
    
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        Array<ER>.validate(as: type, in: runtime)
    }
    
    public static var `default`: Self { Self(events: []) }
}

extension BlockEvents: RuntimeDecodable where ER: RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws  {
        try self.init(events: runtime.decode(from: &decoder))
    }
}

// Can be removed after dropping Metadata V14
public extension SomeBlockEvents {
    static func eventType(events type: TypeDefinition) -> TypeDefinition? {
        (try? BlockEvents<ER>.recordType(events: type)).flatMap {
            ER.eventType(record: $0)
        }
    }
}
