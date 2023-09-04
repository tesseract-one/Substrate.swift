//
//  SubstrateEventRecord.swift
//  
//
//  Created by Yehor Popovych on 22/08/2023.
//

import Foundation
import ScaleCodec

public struct EventRecord<H: Hash>: SomeEventRecord, CompositeStaticValidatableType, CustomStringConvertible
{
    public let phase: EventPhase
    public let header: (name: String, pallet: String)
    public let data: Data
    public let topics: [H]
    
    private let _runtime: any Runtime
    private let _eventTypeId: NetworkType.Id
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public var any: AnyEvent { get throws {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    } }
    
    public func typed<E: PalletEvent>(_ type: E.Type) throws -> E {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    }
    
    public var description: String {
        "{phase: \(phase), event: \(header.pallet).\(header.name), topics: \(topics)}"
    }
    
    @inlinable
    public static var childTypes: Array<ValidatableType.Type> {
        [EventPhase.self, AnyEvent.self, Array<H>.self]
    }
}

public extension EventRecord {
    enum EventPhase: Equatable, Hashable, CustomStringConvertible, IdentifiableType
    {
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
        
        public static var definition: TypeDefinition {
            .variant(variants: [
                .s(0, "ApplyExtrinsic", UInt32.definition), .e(1, "Finalization"),
                .e(2, "Initialization")
            ])
        }
    }
}

extension EventRecord.EventPhase: ScaleCodec.Decodable {
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
        let eventType = runtime.types.event
        self._runtime = runtime
        self.phase = try decoder.decode()
        let info = try AnyEvent.fetchEventData(from: &decoder, runtime: runtime, type: eventType.id)
        self.header = (name: info.name, pallet: info.pallet)
        self._eventTypeId = eventType.id
        self.data = info.data
        self.topics = try Array(from: &decoder) { decoder in
            try runtime.create(
                hash: H.self,
                raw: decoder.decode(.fixed(UInt(runtime.hasher.hashPartByteLength)))
            )
        }
    }
}
