//
//  Signer.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation

public protocol Signer {
    func account(type: KeyTypeId, algos: [CryptoTypeId]) async throws -> PublicKey
    func sign<RC: RuntimeConfig, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: PublicKey,
        config: RC
    ) async throws -> RC.TSignature
}
