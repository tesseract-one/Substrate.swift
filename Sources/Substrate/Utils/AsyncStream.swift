//
//  AsyncStream.swift
//  
//
//  Created by Yehor Popovych on 19/06/2023.
//

import Foundation

public extension AsyncStream {
    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        var iterator: S.AsyncIterator? = nil
        self.init(unfolding: {
            if iterator == nil { iterator = sequence.makeAsyncIterator() }
            return try? await iterator?.next()
        })
    }
    
    init<S: Sequence>(_ sequence: S) where S.Element == Element {
        var iterator = sequence.makeIterator()
        self.init(unfolding: { iterator.next() })
    }
}

public extension AsyncThrowingStream {
    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element, Failure == Error {
        var iterator: S.AsyncIterator? = nil
        self.init(unfolding: {
            if iterator == nil { iterator = sequence.makeAsyncIterator() }
            return try await iterator?.next()
        })
    }
}

public extension AsyncSequence {
    var stream: AsyncStream<Element> { AsyncStream(self) }
    var throwingStream: AsyncThrowingStream<Element, Error> { AsyncThrowingStream(self) }
}

public extension Sequence {
    var stream: AsyncStream<Element> { AsyncStream(self) }
}
