//
//  Signer.swift
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
                data = HBlake2b256.hasher.hash(data: encoder.output)
            } catch {
                cb(.failure(.unknown(error)))
                return
            }
            do {
                let signatureData = try pair.sign(message: data)
                let sender = try R.TAddress(pubKey: account)
                let signature = try R.TSignature(type: account.typeId, bytes: signatureData)
                let extrinsic = SExtrinsic<C, R>(
                    call: payload.call, signed: sender, signature: signature, extra: payload.extra
                )
                cb(.success(extrinsic))
            } catch {
                cb(.failure(.unknown(error)))
            }
        }
    }
}
