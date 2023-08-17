//
//  AnyBlockEvents.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyBlockEvents<ER: SomeEventRecord>: SomeBlockEvents, CustomStringConvertible {
    public typealias ER = ER
    
    public let events: [ER]
    
    public init(events: [ER]) {
        self.events = events
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        guard let typeInfo = runtime.resolve(type: type)?.flatten(runtime) else {
            throw RuntimeDynamicCodableError.typeNotFound(type)
        }
        switch typeInfo.definition {
        case .sequence(of: let recordId):
            let events = try Array<ER>(from: &decoder) { decoder in
                try runtime.decode(from: &decoder) { _ in recordId }
            }
            self.init(events: events)
        default:
            throw RuntimeDynamicCodableError.wrongType(got: typeInfo, for: "Array<EventRecord>")
        }
    }
    
    public func events(extrinsic index: UInt32) -> [ER] {
        events.filter { $0.extrinsicIndex.map{$0 == index} ?? false }
    }
    
    public var description: String {
        events.description
    }
    
    public static var `default`: Self { Self(events: []) }
}
