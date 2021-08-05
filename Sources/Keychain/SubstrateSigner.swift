//
//  SubstrateSigner.swift
//  
//
//  Created by Yehor Popovych on 27.04.2021.
//

import Foundation
import Substrate

extension Keychain: SubstrateSigner {    
    private var queue: DispatchQueue { DispatchQueue.global() }
    
    public func accounts<R: Runtime>(
        with runtime: R.Type,
        format: Ss58AddressFormat,
        _ cb: @escaping SSignerCallback<AccountList<R>>
    ) {
        queue.async {
            cb(.success(AccountList<R>(accounts: self.publicKeys(format: format))))
        }
    }
    
    public func sign<R: Runtime>(
        payload: R.TExtrinsic.SigningPayload,
        with account: PublicKey,
        in runtime: R.Type,
        registry: TypeRegistryProtocol,
        _ cb: @escaping SSignerCallback<R.TExtrinsic>
    ) {
        queue.async {
            guard let pair = self.keyPair(for: account) else {
                cb(.failure(.accountNotFound(account)))
                return
            }
            let data: Data
            do {
                let encoder = SCALE.default.encoder()
                try payload.encode(in: encoder, registry: registry)
                data = encoder.output
            } catch {
                cb(.failure(.badPayload(error: error.localizedDescription)))
                return
            }
            let signatureData = pair.sign(message: data)
            let sender: R.TExtrinsic.SignaturePayload.AddressType
            do {
                sender = try R.TExtrinsic.SignaturePayload.AddressType(pubKey: account)
            } catch {
                cb(.failure(.cantCreateAddress(error: error.localizedDescription)))
                return
            }
            let signature: R.TExtrinsic.SignaturePayload.SignatureType
            do {
                signature = try R.TExtrinsic.SignaturePayload.SignatureType(
                    type: account.typeId, bytes: signatureData
                )
            } catch {
                cb(.failure(.cantCreateSignature(error: error.localizedDescription)))
                return
            }
            do {
                let extrinsic = try R.TExtrinsic(payload: payload)
                    .signed(by: sender, with: signature, payload: payload)
                cb(.success(extrinsic))
            } catch {
                cb(.failure(.cantCreateExtrinsic(error: error.localizedDescription)))
            }
        }
    }
}
