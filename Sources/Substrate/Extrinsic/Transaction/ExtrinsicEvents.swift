//
//  ExtrinsicEvents.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicEvents<R: RootApi> {
    public enum Error: Swift.Error {
        case extrinsicNotFound(ST<R.RC>.Hash)
    }
    
    public let blockEvents: ST<R.RC>.BlockEvents
    public let blockHash: ST<R.RC>.Hash
    public let extrinsicHash: ST<R.RC>.Hash
    public let index: UInt32
    
    public init(events: ST<R.RC>.BlockEvents, blockHash: ST<R.RC>.Hash,
                extrinsicHash: ST<R.RC>.Hash, index: UInt32)
    {
        self.blockEvents = events
        self.blockHash = blockHash
        self.extrinsicHash = extrinsicHash
        self.index = index
    }
    
    public init(api: R, blockHash: ST<R.RC>.Hash, extrinsicHash: ST<R.RC>.Hash) async throws {
        let block = try await api.client.block(at: blockHash, runtime: api.runtime)
        guard let idx = block?.block.extrinsics.firstIndex(where: { $0.hash().raw == extrinsicHash.raw }) else {
            throw Error.extrinsicNotFound(extrinsicHash)
        }
        let events = try await api.client.events(at: blockHash, runtime: api.runtime) ?? .default
        self.init(events: events, blockHash: blockHash, extrinsicHash: extrinsicHash, index: UInt32(idx))
    }
    
    public var events: [ST<R.RC>.BlockEvents.ER] {
        blockEvents.events(extrinsic: index)
    }
    
    public func success() throws -> Self {
        if let error = try first(event: ST<R.RC>.ExtrinsicFailureEvent.self) {
            throw error.error
        }
        return self
    }
}

public extension ExtrinsicEvents {
    @inlinable func has(event: String, pallet: String) -> Bool {
        blockEvents.has(event: event, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func has<E: PalletEvent>(_ type: E.Type) -> Bool {
        blockEvents.has(type, extrinsic: index)
    }
    
    @inlinable func parsed() throws -> [AnyEvent] {
        try blockEvents.parsed(extrinsic: index)
    }
    
    @inlinable func all(records event: String, pallet: String) -> [ST<R.RC>.BlockEvents.ER] {
        blockEvents.all(records: event, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func all(events event: String, pallet: String) throws -> [AnyEvent] {
        try blockEvents.all(events: event, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func all<E: PalletEvent>(records type: E.Type) -> [ST<R.RC>.BlockEvents.ER] {
        blockEvents.all(records: type)
    }
    
    @inlinable func all<E: PalletEvent>(events type: E.Type) throws -> [E] {
        try blockEvents.all(events: type, extrinsic: index)
    }
    
    @inlinable func first(record event: String, pallet: String) -> ST<R.RC>.BlockEvents.ER? {
        blockEvents.first(record: event, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func first(event name: String, pallet: String) throws -> AnyEvent? {
        try blockEvents.first(event: name, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func first<E: PalletEvent>(record type: E.Type) -> ST<R.RC>.BlockEvents.ER? {
        blockEvents.first(record: type, extrinsic: index)
    }
    
    @inlinable func first<E: PalletEvent>(event type: E.Type) throws -> E? {
        try blockEvents.first(event: type, extrinsic: index)
    }
    
    @inlinable func last(record event: String, pallet: String) -> ST<R.RC>.BlockEvents.ER? {
        blockEvents.last(record: event, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func last(event name: String, pallet: String) throws -> AnyEvent? {
        try blockEvents.last(event: name, pallet: pallet, extrinsic: index)
    }
    
    @inlinable func last<E: PalletEvent>(record type: E.Type) -> ST<R.RC>.BlockEvents.ER? {
        blockEvents.last(record: type, extrinsic: index)
    }
    
    @inlinable func last<E: PalletEvent>(event type: E.Type) throws -> E? {
        try blockEvents.last(event: type, extrinsic: index)
    }
    
    @inlinable func _filter<F: ExtrinsicEventsFilter<R>>() -> F {
        .init(blockEvents: blockEvents, index: index)
    }
    
    @inlinable func _filter<F: ExtrinsicEventsFilter<R>>(_: F.Type) -> F {
        _filter()
    }
}

public protocol ExtrinsicEventsFilter<R> {
    associatedtype R: RootApi
    
    var blockEvents: ST<R.RC>.BlockEvents { get }
    var index: UInt32 { get }
    
    init(blockEvents: ST<R.RC>.BlockEvents, index: UInt32)
    static var pallet: String { get }
}

public struct ExtrinsicEventsEventFilter<R: RootApi, E: PalletEvent> {
    private let blockEvents: ST<R.RC>.BlockEvents
    private let index: UInt32
    
    public init(blockEvents: ST<R.RC>.BlockEvents, index: UInt32) {
        self.blockEvents = blockEvents
        self.index = index
    }
    
    public var present: Bool {
        blockEvents.has(E.self, extrinsic: index)
    }
    
    public var all: [E] { get throws {
        try blockEvents.all(events: E.self, extrinsic: index)
    } }
    
    public var allRecords: [ST<R.RC>.BlockEvents.ER] {
        blockEvents.all(records: E.self, extrinsic: index)
    }
    
    public var first: E? { get throws {
        try blockEvents.first(event: E.self, extrinsic: index)
    } }
    
    public var firstRecord: ST<R.RC>.BlockEvents.ER? {
        blockEvents.first(record: E.self, extrinsic: index)
    }
    
    public var last: E? { get throws {
        try blockEvents.last(event: E.self, extrinsic: index)
    } }
    
    public var lastRecord: ST<R.RC>.BlockEvents.ER? {
        blockEvents.last(record: E.self, extrinsic: index)
    }
}
