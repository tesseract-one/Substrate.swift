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
    
    public func sign<C, R>(
        payload: SSigningPayload<C, R>,
        with account: PublicKey,
        in runtime: R.Type,
        registry: TypeRegistryProtocol,
        _ cb: @escaping SSignerCallback<SExtrinsic<C, R>>
    ) where C : AnyCall, R : Runtime {
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
            let sender: R.TAddress
            do {
                sender = try R.TAddress(pubKey: account)
            } catch {
                cb(.failure(.cantCreateAddress(error: error.localizedDescription)))
                return
            }
            let signature: R.TSignature
            do {
                signature = try R.TSignature(type: account.typeId, bytes: signatureData)
            } catch {
                cb(.failure(.cantCreateSignature(error: error.localizedDescription)))
                return
            }
            let extrinsic = SExtrinsic<C, R>(
                call: payload.call, signed: sender, signature: signature, extra: payload.extra
            )
            cb(.success(extrinsic))
        }
    }
}
