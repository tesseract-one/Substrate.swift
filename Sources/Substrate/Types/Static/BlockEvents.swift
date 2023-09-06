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
                                       as info: NetworkType.Info,
                                       runtime: Runtime) throws
    {
        let recordId = try Self.recordTypeId(metadata: runtime.metadata, events: info)
        let events = try Array<ER>(from: &decoder) { decoder in
            try runtime.decode(from: &decoder) { _ in recordId }
        }
        self.init(events: events)
    }
    
    public func events(extrinsic index: UInt32) -> [ER] {
        events.filter { $0.extrinsicIndex.map{$0 == index} ?? false }
    }
    
    public var description: String {
        events.description
    }
    
    public static func recordTypeId(metadata: any Metadata, events info: NetworkType.Info) throws -> NetworkType.Id {
        switch info.type.flatten(metadata).definition {
        case .sequence(of: let recordId):
            return recordId
        default:
            throw TypeError.wrongType(for: Self.self, got: info.type,
                                      reason: "Not a sequence")
        }
    }
    
    public static func validate(runtime: any Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError> {
        Array<ER>.validate(runtime: runtime, type: type)
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
    static func eventTypeId(metadata: any Metadata, events info: NetworkType.Info) -> NetworkType.Id? {
        (try? BlockEvents<ER>.recordTypeId(metadata: metadata, events: info)).flatMap {
            ER.eventTypeId(metadata: metadata, record: $0)
        }
    }
}
