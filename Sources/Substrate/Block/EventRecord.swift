//
//  EventRecord.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation
import ScaleCodec

public enum EventPhase: Equatable, Hashable {
    // Applying an extrinsic.
    case applyExtrinsic(UInt32)
    // Finalizing the block.
    case finalization
    // Initializing the block.
    case initialization
}

public struct EventRecord<H: Hash, E: Event> {
    public let phase: EventPhase
    public let event: E
    public let topics: [H]
}

extension EventPhase: ScaleDecodable {
    public init(from decoder: ScaleDecoder) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .applyExtrinsic(decoder.decode())
        case 1: self = .finalization
        case 2: self = .initialization
        default: throw decoder.enumCaseError(for: opt)
        }
    }
}

extension EventRecord: ScaleRuntimeDecodable {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        self.phase = try decoder.decode()
        self.event = try E(from: decoder, runtime: runtime)
        self.topics = try Array(from: decoder) { decoder in
            try H(decoder.decode(.fixed(UInt(runtime.hasher.hashPartByteLength))))
        }
    }
}

extension EventRecord where E == AnyEvent {
    public func typed<SE: StaticEvent>(_ type: SE.Type) throws -> EventRecord<H, SE> {
        guard SE.pallet == event.pallet && SE.name == event.name else {
            throw EventDecodingError.foundWrongEvent(found: (SE.name, SE.pallet),
                                                     expected: (event.name, event.pallet))
        }
        return try EventRecord<H, SE>(phase: phase,
                                      event: SE(params: event.params, info: event.info),
                                      topics: topics)
    }
}
