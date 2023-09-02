//
//  BlockEvents.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct BlockEvents<ER: SomeEventRecord>: SomeBlockEvents, CustomStringConvertible {
    public typealias ER = ER
    
    public let events: [ER]
    
    public init(events: [ER]) {
        self.events = events
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: NetworkType.Id,
                                       runtime: Runtime) throws
    {
        let recordId = try Self.recordTypeId(metadata: runtime.metadata, events: type)
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
    
    public static func recordTypeId(metadata: any Metadata, events id: NetworkType.Id) throws -> NetworkType.Id {
        guard let typeInfo = metadata.resolve(type: id)?.flatten(metadata) else {
            throw DynamicCodableError.typeNotFound(id)
        }
        switch typeInfo.definition {
        case .sequence(of: let recordId):
            return recordId
        default:
            throw DynamicCodableError.wrongType(got: typeInfo,
                                                       for: "Array<EventRecord>")
        }
    }
    
    public static func validate(runtime: any Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError> {
        guard let typeInfo = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        switch typeInfo.definition {
        case .sequence(of: let recordId):
            return ER.validate(runtime: runtime, type: recordId)
        default:
            return .failure(.wrongType(got: typeInfo, for: "Array<EventRecord>"))
        }
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
    static func eventTypeId(metadata: any Metadata, events id: NetworkType.Id) -> NetworkType.Id? {
        (try? BlockEvents<ER>.recordTypeId(metadata: metadata, events: id)).flatMap {
            ER.eventTypeId(metadata: metadata, record: $0)
        }
    }
}
