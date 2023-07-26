//
//  EventRecord.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation
import ScaleCodec

public enum EventPhase: Equatable, Hashable, CustomStringConvertible {
    // Applying an extrinsic.
    case applyExtrinsic(UInt32)
    // Finalizing the block.
    case finalization
    // Initializing the block.
    case initialization
    
    public var description: String {
        switch self {
        case .applyExtrinsic(let index): return "apply #\(index)"
        case .finalization: return "finalization"
        case .initialization: return "initialization"
        }
    }
}

public protocol SomeEventRecord: RuntimeDecodable {
    var extrinsicIndex: UInt32? { get }
    var header: (name: String, pallet: String) { get }
    var any: AnyEvent { get throws }
    func typed<E: IdentifiableEvent>(_ type: E.Type) throws -> E
}

public struct EventRecord<H: Hash>: SomeEventRecord, CustomStringConvertible {
    public let phase: EventPhase
    public let header: (name: String, pallet: String)
    public let data: Data
    public let topics: [H]
    
    private let _runtime: any Runtime
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public var any: AnyEvent { get throws {
        try _runtime.decode(event: AnyEvent.self, from: data)
    } }
    
    public func typed<E: IdentifiableEvent>(_ type: E.Type) throws -> E {
        try _runtime.decode(event: E.self, from: data)
    }
    
    public var description: String {
        "{phase: \(phase), event: \(header.pallet).\(header.name), topics: \(topics)}"
    }
}

extension EventPhase: ScaleCodec.Decodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .applyExtrinsic(decoder.decode())
        case 1: self = .finalization
        case 2: self = .initialization
        default: throw decoder.enumCaseError(for: opt)
        }
    }
}

extension EventRecord: RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        self._runtime = runtime
        self.phase = try decoder.decode()
        let info = try AnyEvent.fetchEventData(from: &decoder, runtime: runtime)
        self.header = (name: info.name, pallet: info.pallet)
        self.data = info.data
        self.topics = try Array(from: &decoder) { decoder in
            try runtime.create(
                hash: H.self,
                raw: decoder.decode(.fixed(UInt(runtime.hasher.hashPartByteLength)))
            )
        }
    }
}
