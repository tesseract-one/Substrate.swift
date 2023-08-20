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
    public func account(type: KeyTypeId, algos: [CryptoTypeId]) async -> Result<any PublicKey, SignerError> {
        let result = await self.delegate.account(in: self, for: type, algorithms: algos)
        switch result {
        case .noAccount: return .failure(.noAccounts(for: type, and: algos))
        case .cancelled: return .failure(.cancelledByUser)
        case .account(let pub): return .success(pub)
        }
    }
    
    public func sign<RC: Config, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: any PublicKey,
        runtime: ExtendedRuntime<RC>
    ) async -> Result<RC.TSignature, SignerError> {
        guard let pair = keyPair(for: account) else {
            return .failure(.accountNotFound(account))
        }
        return await pair.sign(payload: payload, with: account, runtime: runtime)
    }
}

public extension KeyPair {
    func account(type: KeyTypeId, algos: [CryptoTypeId]) async -> Result<any PublicKey, SignerError> {
        guard algos.firstIndex(of: algorithm) != nil else {
            return .failure(.noAccounts(for: type, and: algos))
        }
        return .success(pubKey)
    }
    
    func sign<RC: Config, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: any PublicKey,
        runtime: ExtendedRuntime<RC>
    ) async -> Result<RC.TSignature, SignerError> {
        guard self.pubKey.raw == account.raw else {
            return .failure(.accountNotFound(account))
        }
        var encoder = runtime.encoder()
        do {
            try runtime.extrinsicManager.encode(payload: payload, in: &encoder, runtime: runtime)
        } catch {
            return .failure(.badPayload(error: error.localizedDescription))
        }
        let signature = sign(message: encoder.output)
        do {
            let signature = try runtime.create(signature: RC.TSignature.self,
                                               raw: signature.raw,
                                               algorithm: signature.algorithm)
            return .success(signature)
        } catch {
            return .failure(.cantCreateSignature(error: error.localizedDescription))
        }
    }
}

extension EcdsaKeyPair: Signer {}
extension Ed25519KeyPair: Signer {}
extension Sr25519KeyPair: Signer {}
