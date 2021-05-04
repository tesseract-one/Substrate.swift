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
    
    public func accounts<R>(with runtime: R.Type, _ cb: @escaping SSignerCallback<[R.TAccountId], R>) where R : Runtime {
        queue.async {
            do {
                let accounts = try self.accounts(for: runtime)
                cb(.success(accounts))
            } catch let e as SubstrateSignerError<R> {
                cb(.failure(e))
            } catch {
                cb(.failure(.unknown(error)))
            }
        }
    }
    
    public func sign<C, R>(payload: SSigningPayload<C, R>, in runtime: R.Type, with account: R.TAccountId, _ cb: @escaping SSignerCallback<SExtrinsic<C, R>, R>) where C : AnyCall, R : Runtime {
        
    }
}
