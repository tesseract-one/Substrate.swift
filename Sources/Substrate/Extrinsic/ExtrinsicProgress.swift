//
//  ExtrinsicProgress.swift
//  
//
//  Created by Yehor Popovych on 29/05/2023.
//

import Foundation

public struct ExtrinsicProgress<S: SomeSubstrate> {
    public enum Error: Swift.Error {
        case transactionFailed(S.RC.TTransactionStatus)
    }

    private let substrate: S
    private let hash: S.RC.THasher.THash
    private let stream: AsyncThrowingStream<S.RC.TTransactionStatus, Swift.Error>
    
    public init(substrate: S,
                hash: S.RC.THasher.THash,
                stream: AsyncThrowingStream<S.RC.TTransactionStatus, Swift.Error>) {
        self.substrate = substrate
        self.stream = stream
        self.hash = hash
    }
    
    public var progress: AsyncThrowingStream<S.RC.TTransactionStatus, Swift.Error> { stream }
    
    public func waitForInBlockHash() async throws -> S.RC.TBlock.THeader.THasher.THash {
        for try await status in stream {
            if status.isInBlock || status.isFinalized {
                return status.blockHash!
            } else if status.isFinished { // Finished but not in block / finalized. Some error
                throw Error.transactionFailed(status)
            }
        }
        fatalError("Should be unreachable!")
    }
    
    public func waitForFinalizedHash() async throws -> S.RC.TBlock.THeader.THasher.THash {
        for try await status in stream {
            if status.isFinalized {
                return status.blockHash!
            } else if status.isFinished { // Finished but not finalized. Some error
                throw Error.transactionFailed(status)
            }
        }
        fatalError("Should be unreachable!")
    }
    
    public func waitForInBlock() async throws -> ExtrinsicEvents<S.RC.THasher.THash, S.RC.TBlockEvents, S.RC.TExtrinsicFailureEvent> {
        let hash = try await waitForInBlockHash()
        return try await ExtrinsicEvents(substrate: substrate, blockHash: hash, extrinsicHash: self.hash)
    }
    
    public func waitForFinalized() async throws -> ExtrinsicEvents<S.RC.THasher.THash, S.RC.TBlockEvents, S.RC.TExtrinsicFailureEvent> {
        let hash = try await waitForFinalizedHash()
        return try await ExtrinsicEvents(substrate: substrate, blockHash: hash, extrinsicHash: self.hash)
    }
}
