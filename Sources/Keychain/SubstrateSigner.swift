//
//  SubstrateSigner.swift
//  
//
//  Created by Yehor Popovych on 27.04.2021.
//

import Foundation
#if !COCOAPODS
import Substrate
#endif

extension Keychain: Signer {
    public func account(type: KeyTypeId, algos: [CryptoTypeId]) async throws -> any PublicKey {
        let pubkeys = publicKeys.filter { algos.firstIndex(of: $0.algorithm) != nil }
        guard pubkeys.count > 0 else {
            throw SignerError.noAccounts(for: type, and: algos)
        }
        guard let key = await self.delegate.account(type: type, keys: pubkeys) else {
            throw SignerError.cancelledByUser
        }
        return key
    }
    
    public func sign<RC: Config, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: any PublicKey,
        runtime: ExtendedRuntime<RC>
    ) async throws -> RC.TSignature {
        guard let pair = keyPair(for: account) else {
            throw SignerError.accountNotFound(account)
        }
        return try await pair.sign(payload: payload, with: account, runtime: runtime)
    }
}

public extension KeyPair {
    func account(type: KeyTypeId, algos: [CryptoTypeId]) async throws -> any PublicKey {
        guard algos.firstIndex(of: algorithm) != nil else {
            throw SignerError.noAccounts(for: type, and: algos)
        }
        return pubKey
    }
    
    func sign<RC: Config, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: any PublicKey,
        runtime: ExtendedRuntime<RC>
    ) async throws -> RC.TSignature {
        guard self.pubKey.raw == account.raw else {
            throw SignerError.accountNotFound(account)
        }
        var encoder = runtime.encoder()
        do {
            try runtime.extrinsicManager.encode(payload: payload, in: &encoder)
        } catch {
            throw SignerError.badPayload(error: error.localizedDescription)
        }
        let signature = sign(message: encoder.output)
        do {
            return try RC.TSignature(raw: signature.raw, algorithm: signature.algorithm, runtime: runtime)
        } catch {
            throw SignerError.cantCreateSignature(error: error.localizedDescription)
        }
    }
}

extension EcdsaKeyPair: Signer {}
extension Ed25519KeyPair: Signer {}
extension Sr25519KeyPair: Signer {}
