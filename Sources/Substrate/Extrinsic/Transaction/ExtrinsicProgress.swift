//
//  ExtrinsicProgress.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation

public protocol SomeTransactionStatus<BlockHash>: RuntimeSwiftDecodable {
    associatedtype BlockHash: Hash
    
    var isFinalized: Bool { get }
    var isFinished: Bool { get }
    var isInBlock: Bool { get }
    var blockHash: BlockHash? { get }
}


public struct ExtrinsicProgress<R: RootApi> {
    public enum Error: Swift.Error {
        case transactionFailed(ST<R.RC>.TransactionStatus)
    }

    private let api: R
    private let hash: ST<R.RC>.Hash
    private let stream: AsyncThrowingStream<ST<R.RC>.TransactionStatus, Swift.Error>
    
    public init(api: R,
                hash: ST<R.RC>.Hash,
                stream: AsyncThrowingStream<ST<R.RC>.TransactionStatus, Swift.Error>) {
        self.api = api
        self.stream = stream
        self.hash = hash
    }
    
    public var progress: AsyncThrowingStream<ST<R.RC>.TransactionStatus, Swift.Error> { stream }
    
    public func waitForInBlockHash() async throws -> ST<R.RC>.Hash {
        for try await status in stream {
            if status.isInBlock || status.isFinalized {
                return status.blockHash!
            } else if status.isFinished { // Finished but not in block / finalized. Some error
                throw Error.transactionFailed(status)
            }
        }
        fatalError("Should be unreachable!")
    }
    
    public func waitForFinalizedHash() async throws -> ST<R.RC>.Hash {
        for try await status in stream {
            if status.isFinalized {
                return status.blockHash!
            } else if status.isFinished { // Finished but not finalized. Some error
                throw Error.transactionFailed(status)
            }
        }
        fatalError("Should be unreachable!")
    }
    
    public func waitForInBlock() async throws -> ExtrinsicEvents<R> {
        let hash = try await waitForInBlockHash()
        return try await ExtrinsicEvents(api: api, blockHash: hash, extrinsicHash: self.hash)
    }
    
    public func waitForFinalized() async throws -> ExtrinsicEvents<R> {
        let hash = try await waitForFinalizedHash()
        return try await ExtrinsicEvents(api: api, blockHash: hash, extrinsicHash: self.hash)
    }
}
