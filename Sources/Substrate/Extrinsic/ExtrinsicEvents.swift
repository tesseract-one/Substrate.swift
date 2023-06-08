//
//  ExtrinsicEvents.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation

public protocol SomeExtrinsicFailureEvent<Err>: StaticEvent {
    associatedtype Err: SomeDispatchError
    func asError() throws -> Err
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
    
    public init<S>(substrate: S, blockHash: H, extrinsicHash: H) async throws
        where S: SomeSubstrate, H == S.RC.THasher.THash, BE == S.RC.TBlockEvents
    {
        let block = try await substrate.client.block(at: blockHash, runtime: substrate.runtime)
        guard let idx = block?.block.extrinsics.firstIndex(where: { $0.hash().data == extrinsicHash.data }) else {
            throw Error.extrinsicNotFound(extrinsicHash)
        }
        let events = try await substrate.client.events(at: blockHash, runtime: substrate.runtime) ?? .default
        self.init(events: events, blockHash: blockHash, extrinsicHash: extrinsicHash, index: UInt32(idx))
    }
    
    public var events: [BE.ER] {
        _events.events(extrinsic: index)
    }
    
    public var blockEvents: BE { _events }
    
    public func success() throws -> Self {
        if let error = try first(event: Failure.self) {
            throw try error.asError()
        }
        return self
    }
}


public extension ExtrinsicEvents {
    func has(event: String, pallet: String) -> Bool {
        _events.has(event: event, pallet: pallet, extrinsic: index)
    }
    
    func has<E: StaticEvent>(_ type: E.Type) -> Bool {
        _events.has(type, extrinsic: index)
    }
    
    func all(records event: String, pallet: String) -> [BE.ER] {
        _events.all(records: event, pallet: pallet, extrinsic: index)
    }
    
    func all(events event: String, pallet: String) throws -> [AnyEvent] {
        try _events.all(events: event, pallet: pallet, extrinsic: index)
    }
    
    func all<E: StaticEvent>(records type: E.Type) -> [BE.ER] {
        _events.all(records: type)
    }
    
    func all<E: StaticEvent>(events type: E.Type) throws -> [E] {
        try _events.all(events: type, extrinsic: index)
    }
    
    func first(record event: String, pallet: String) -> BE.ER? {
        _events.first(record: event, pallet: pallet, extrinsic: index)
    }
    
    func first(event name: String, pallet: String) throws -> AnyEvent? {
        try _events.first(event: name, pallet: pallet, extrinsic: index)
    }
    
    func first<E: StaticEvent>(record type: E.Type) -> BE.ER? {
        _events.first(record: type, extrinsic: index)
    }
    
    func first<E: StaticEvent>(event type: E.Type) throws -> E? {
        try _events.first(event: type, extrinsic: index)
    }
    
    func last(record event: String, pallet: String) -> BE.ER? {
        _events.last(record: event, pallet: pallet, extrinsic: index)
    }
    
    func last(event name: String, pallet: String) throws -> AnyEvent? {
        try _events.last(event: name, pallet: pallet, extrinsic: index)
    }
    
    func last<E: StaticEvent>(record type: E.Type) -> BE.ER? {
        _events.last(record: type, extrinsic: index)
    }
    
    func last<E: StaticEvent>(event type: E.Type) throws -> E? {
        try _events.last(event: type, extrinsic: index)
    }
}