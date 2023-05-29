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
    private let stream: AsyncThrowingStream<S.RC.TTransactionStatus, Swift.Error>
    
    public init(substrate: S, stream: AsyncThrowingStream<S.RC.TTransactionStatus, Swift.Error>) {
        self.substrate = substrate
        self.stream = stream
    }
    
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
    
    public mutating func waitForInBlock() async throws -> S.RC.TBlock.THeader.THasher.THash {
        try await waitForInBlockHash()
    }
}
