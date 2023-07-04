//
//  ExtrinsicProgress.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation

public struct ExtrinsicProgress<R: RootApi> {
    public enum Error: Swift.Error {
        case transactionFailed(R.RC.TTransactionStatus)
    }

    private let api: R
    private let hash: R.RC.THasher.THash
    private let stream: AsyncThrowingStream<R.RC.TTransactionStatus, Swift.Error>
    
    public init(api: R,
                hash: R.RC.THasher.THash,
                stream: AsyncThrowingStream<R.RC.TTransactionStatus, Swift.Error>) {
        self.api = api
        self.stream = stream
        self.hash = hash
    }
    
    public var progress: AsyncThrowingStream<R.RC.TTransactionStatus, Swift.Error> { stream }
    
    public func waitForInBlockHash() async throws -> R.RC.TBlock.THeader.THasher.THash {
        for try await status in stream {
            if status.isInBlock || status.isFinalized {
                return status.blockHash!
            } else if status.isFinished { // Finished but not in block / finalized. Some error
                throw Error.transactionFailed(status)
            }
        }
        fatalError("Should be unreachable!")
    }
    
    public func waitForFinalizedHash() async throws -> R.RC.TBlock.THeader.THasher.THash {
        for try await status in stream {
            if status.isFinalized {
                return status.blockHash!
            } else if status.isFinished { // Finished but not finalized. Some error
                throw Error.transactionFailed(status)
            }
        }
        fatalError("Should be unreachable!")
    }
    
    public func waitForInBlock() async throws -> ExtrinsicEvents<R.RC.THasher.THash, R.RC.TBlockEvents, R.RC.TExtrinsicFailureEvent> {
        let hash = try await waitForInBlockHash()
        return try await ExtrinsicEvents(api: api, blockHash: hash, extrinsicHash: self.hash)
    }
    
    public func waitForFinalized() async throws -> ExtrinsicEvents<R.RC.THasher.THash, R.RC.TBlockEvents, R.RC.TExtrinsicFailureEvent> {
        let hash = try await waitForFinalizedHash()
        return try await ExtrinsicEvents(api: api, blockHash: hash, extrinsicHash: self.hash)
    }
}
