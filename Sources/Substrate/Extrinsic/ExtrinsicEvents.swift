//
//  ExtrinsicEvents.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation


public struct ExtrinsicEvents<H: Hash, Failure: SomeExtrinsicFailureEvent> {
    private let _events: Array<EventRecord<H, AnyEvent>>
    public let blockHash: H
    public let extrinsicHash: H
    public let index: Int
    
    public init(events: Array<EventRecord<H, AnyEvent>>, blockHash: H, extrinsicHash: H, index: Int) {
        self._events = events
        self.blockHash = blockHash
        self.extrinsicHash = extrinsicHash
        self.index = index
    }
    
    public init<S>(substrate: S, blockHash: H, extrinsicHash: H) async throws
        where S: SomeSubstrate, H == S.RC.THasher.THash
    {
        let block = try await substrate.rpc.chain.block(at: blockHash)
        guard let idx = block.block.extrinsics.firstIndex(where: { $0.hash().data == extrinsicHash.data }) else {
            
        }
        let events = try await substrate.query.events(at: blockHash)
        self.init(events: events, blockHash: blockHash, extrinsicHash: extrinsicHash, index: idx)
    }
    
    public var events: Array<EventRecord<H, AnyEvent>> {
        _events.filter { $0.phase == .applyExtrinsic(UInt32(index)) }
    }
    
    public var allBlockEvents: Array<EventRecord<H, AnyEvent>> { _events }
    
    public func success() throws -> Self {
        if let error = try first(Failure.self) {
            throw try error.event.asError()
        }
        return self
    }
}


public extension ExtrinsicEvents {
    func has(event: String, pallet: String) -> Bool {
        events.first { $0.event.name == event && $0.event.pallet == pallet } != nil
    }
    
    func has<E: StaticEvent>(_ type: E.Type) -> Bool {
        has(event: E.name, pallet: E.pallet)
    }
    
    func all(event: String, pallet: String) -> [EventRecord<H, AnyEvent>] {
        events.filter { $0.event.name == event && $0.event.pallet == pallet }
    }
    
    func all<E: StaticEvent>(_ type: E.Type) throws -> [EventRecord<H, E>] {
        try events.filter { $0.event.name == E.name && $0.event.pallet == E.pallet }.map { try $0.typed(type) }
    }
    
    func first(event: String, pallet: String) -> EventRecord<H, AnyEvent>? {
        events.first { $0.event.name == event && $0.event.pallet == pallet }
    }
    
    func first<E: StaticEvent>(_ type: E.Type) throws -> EventRecord<H, E>? {
        try events.first { $0.event.name == E.name && $0.event.pallet == E.pallet }?.typed(type)
    }
    
    func last(event: String, pallet: String) -> EventRecord<H, AnyEvent>? {
        events.last { $0.event.name == event && $0.event.pallet == pallet }
    }
    
    func last<E: StaticEvent>(_ type: E.Type) throws -> EventRecord<H, E>? {
        try events.last { $0.event.name == E.name && $0.event.pallet == E.pallet }?.typed(type)
    }
}
