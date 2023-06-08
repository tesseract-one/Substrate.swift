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

public protocol SomeEventRecord: ScaleRuntimeDecodable {
    var extrinsicIndex: UInt32? { get }
    func header() -> (name: String, pallet: String)
    func any() throws -> AnyEvent
    func typed<E: StaticEvent>(_ type: E.Type) throws -> E
}

public struct EventRecord<H: Hash>: SomeEventRecord {
    public let phase: EventPhase
    public let event: AnyEvent
    public let topics: [H]
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public func header() -> (name: String, pallet: String) {
        (event.name, event.pallet)
    }
    
    public func any() throws -> AnyEvent { event }
    
    public func typed<E: StaticEvent>(_ type: E.Type) throws -> E {
        try event.typed(type)
    }
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
        self.event = try AnyEvent(from: decoder, runtime: runtime)
        self.topics = try Array(from: decoder) { decoder in
            try H(decoder.decode(.fixed(UInt(runtime.hasher.hashPartByteLength))))
        }
    }
}
