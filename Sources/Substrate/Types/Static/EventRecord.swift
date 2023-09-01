//
//  SubstrateEventRecord.swift
//  
//
//  Created by Yehor Popovych on 22/08/2023.
//

import Foundation
import ScaleCodec

public struct EventRecord<H: Hash>: SomeEventRecord, CustomStringConvertible {
    public let phase: EventPhase
    public let header: (name: String, pallet: String)
    public let data: Data
    public let topics: [H]
    
    private let _runtime: any Runtime
    private let _eventTypeId: RuntimeType.Id
    
    public var extrinsicIndex: UInt32? {
        switch phase {
        case .applyExtrinsic(let index): return index
        default: return nil
        }
    }
    
    public var any: AnyEvent { get throws {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    } }
    
    public func typed<E: IdentifiableEvent>(_ type: E.Type) throws -> E {
        try _runtime.decode(from: data) { _ in _eventTypeId }
    }
    
    public var description: String {
        "{phase: \(phase), event: \(header.pallet).\(header.name), topics: \(topics)}"
    }
}

public extension EventRecord {
    enum EventPhase: Equatable, Hashable, CustomStringConvertible {
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

extension EventRecord.EventPhase: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError> {
        guard let info = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        guard case .variant(variants: let variants) = info.definition, variants.count == 3 else {
            return .failure(.wrongType(got: info, for: "EventPhase"))
        }
        guard variants[0].name.lowercased() == "applyextrinsic", variants[0].index == 0 else {
            return .failure(.variantNotFound(name: "ApplyExtrinsic", in: info))
        }
        guard variants[1].name.lowercased() == "finalization", variants[1].index == 1 else {
            return .failure(.variantNotFound(name: "Finalization", in: info))
        }
        guard variants[2].name.lowercased() == "initialization", variants[2].index == 2 else {
            return .failure(.variantNotFound(name: "Initialization", in: info))
        }
        return .success(())
    }
}

extension EventRecord: RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let eventType = try runtime.types.event
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

extension EventRecord: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        guard case .composite(fields: let fields) = info.definition, fields.count == 3 else {
            return .failure(.wrongType(got: info, for: "EventPhase"))
        }
        return EventPhase.validate(runtime: runtime, type: fields[0].type)
            .flatMap { AnyEvent.validate(runtime: runtime, type: fields[1].type) }
            .flatMap { [H].validate(runtime: runtime, type: fields[2].type) }
    }
    
    
}
