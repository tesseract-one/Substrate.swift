//
//  Signer.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation

public protocol Signer {
    func account(type: KeyTypeId, algos: [CryptoTypeId]) async throws -> any PublicKey
    func sign<RC: RuntimeConfig, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: any PublicKey,
        runtime: ExtendedRuntime<RC>
    ) async throws -> RC.TSignature
}

public enum SignerError: Error {
    case accountNotFound(any PublicKey)
    case badPayload(error: String)
    case cantCreateSignature(error: String)
    case cantBeConnected
    case cancelledByUser
    case unknown(error: String)
}
