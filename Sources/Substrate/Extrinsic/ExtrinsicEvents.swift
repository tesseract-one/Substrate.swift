//
//  ExtrinsicEvents.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation
import ScaleCodec

public protocol SomeExtrinsicFailureEvent: IdentifiableEvent {
    associatedtype Err: Error
    var error: Err { get }
}

public struct ExtrinsicEvents<H: Hash, BE: SomeBlockEvents, Failure: SomeExtrinsicFailureEvent> {
    public enum Error: Swift.Error {
        case extrinsicNotFound(H)
    }
    
    private let _events: BE
    public let blockHash: H
    public let extrinsicHash: H
    public let index: UInt32
    
    public init(events: BE, blockHash: H, extrinsicHash: H, index: UInt32) {
        self._events = events
        self.blockHash = blockHash
        self.extrinsicHash = extrinsicHash
        self.index = index
    }
    
    public init<R>(api: R, blockHash: H, extrinsicHash: H) async throws
        where R: RootApi, H == R.RC.THasher.THash, BE == R.RC.TBlockEvents
    {
        let block = try await api.client.block(at: blockHash, runtime: api.runtime)
        guard let idx = block?.block.extrinsics.firstIndex(where: { $0.hash().data == extrinsicHash.data }) else {
            throw Error.extrinsicNotFound(extrinsicHash)
        }
        let events = try await api.client.events(at: blockHash, runtime: api.runtime) ?? .default
        self.init(events: events, blockHash: blockHash, extrinsicHash: extrinsicHash, index: UInt32(idx))
    }
    
    public var events: [BE.ER] {
        _events.events(extrinsic: index)
    }
    
    public var blockEvents: BE { _events }
    
    public func success() throws -> Self {
        if let error = try first(event: Failure.self) {
            throw error.error
        }
        return self
    }
}

public extension ExtrinsicEvents {
    func has(event: String, pallet: String) -> Bool {
        _events.has(event: event, pallet: pallet, extrinsic: index)
    }
    
    func has<E: IdentifiableEvent>(_ type: E.Type) -> Bool {
        _events.has(type, extrinsic: index)
    }
    
    func parsed() throws -> [AnyEvent] {
        try _events.parsed(extrinsic: index)
    }
    
    func all(records event: String, pallet: String) -> [BE.ER] {
        _events.all(records: event, pallet: pallet, extrinsic: index)
    }
    
    func all(events event: String, pallet: String) throws -> [AnyEvent] {
        try _events.all(events: event, pallet: pallet, extrinsic: index)
    }
    
    func all<E: IdentifiableEvent>(records type: E.Type) -> [BE.ER] {
        _events.all(records: type)
    }
    
    func all<E: IdentifiableEvent>(events type: E.Type) throws -> [E] {
        try _events.all(events: type, extrinsic: index)
    }
    
    func first(record event: String, pallet: String) -> BE.ER? {
        _events.first(record: event, pallet: pallet, extrinsic: index)
    }
    
    func first(event name: String, pallet: String) throws -> AnyEvent? {
        try _events.first(event: name, pallet: pallet, extrinsic: index)
    }
    
    func first<E: IdentifiableEvent>(record type: E.Type) -> BE.ER? {
        _events.first(record: type, extrinsic: index)
    }
    
    func first<E: IdentifiableEvent>(event type: E.Type) throws -> E? {
        try _events.first(event: type, extrinsic: index)
    }
    
    func last(record event: String, pallet: String) -> BE.ER? {
        _events.last(record: event, pallet: pallet, extrinsic: index)
    }
    
    func last(event name: String, pallet: String) throws -> AnyEvent? {
        try _events.last(event: name, pallet: pallet, extrinsic: index)
    }
    
    func last<E: IdentifiableEvent>(record type: E.Type) -> BE.ER? {
        _events.last(record: type, extrinsic: index)
    }
    
    func last<E: IdentifiableEvent>(event type: E.Type) throws -> E? {
        try _events.last(event: type, extrinsic: index)
    }
}

public struct AnyExtrinsicFailureEvent: SomeExtrinsicFailureEvent {
    public struct ExtrinsicFailed: Error {
        public let body: Value<RuntimeType.Id>
    }
    public typealias Err = ExtrinsicFailed
    public let error: ExtrinsicFailed
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: RuntimeType.Id, runtime: Runtime) throws {
        let value = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
        self.error = ExtrinsicFailed(body: value)
    }
    
    public static let pallet: String = "System"
    public static let name: String = "ExtrinsicFailed"
}
