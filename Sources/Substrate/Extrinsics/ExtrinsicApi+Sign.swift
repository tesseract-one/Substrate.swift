//
//  ExtrinsicApi+Sign.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

extension SubstrateExtrinsicApi {
    public func accounts(_ cb: @escaping SExtrinsicApiCallback<AccountList<S.R>, S.R>) {
        guard let signer = substrate.signer else {
            cb(.failure(.dontHaveSigner))
            return
        }
        signer.accounts(with: S.R.self, format: substrate.properties.ss58Format) {
            cb($0.mapError(SubstrateExtrinsicApiError<S.R>.signer))
        }
    }
    
    public func sign(call: AnyCall,
                     extra: S.R.TExtrinsic.SigningPayload.Extra,
                     with account: S.R.TAccountId,
                     _ cb: @escaping SExtrinsicApiCallback<S.R.TExtrinsic, S.R>)
    {
        guard let signer = substrate.signer else {
            cb(.failure(.dontHaveSigner))
            return
        }
        guard account.format == substrate.properties.ss58Format else {
            cb(.failure(.badSs58Format(format: account.format, expected: substrate.properties.ss58Format)))
            return
        }
        do {
            let payload = try S.R.TExtrinsic(call: call, signature: nil).payload(with: extra)
            signer.sign(payload: payload, with: account, in: S.R.self, registry: substrate.registry) { res in
                cb(res.mapError(SubstrateExtrinsicApiError<S.R>.signer))
            }
        } catch {
            cb(.failure(.payload(error: error)))
        }
    }
    
    public func signAndSubmit(call: AnyCall,
                              extra: S.R.TExtrinsic.SigningPayload.Extra,
                              with account: S.R.TAccountId,
                              timeout: TimeInterval? = nil,
                              _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>)
    {
        self.sign(call: call, extra: extra, with: account) {
            $0.pour(error: cb).onSuccess { extrinsic in
                self.submit(extrinsic: extrinsic, timeout: timeout, cb)
            }
        }
    }
}

extension SubstrateExtrinsicApi where S.R: ExtrinsicExtraProvider {
    public func signAndSubmit(
        call: AnyCall, with account: S.R.TAccountId,
        options: S.R.TExtraOptions, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        S.R.createExtra(accountId: account,
                        options: options,
                        timeout: timeout ?? substrate.callTimeout,
                        substrate: substrate) { res in
            res
                .mapError(SubstrateExtrinsicApiError<S.R>.rpc)
                .pour(error: cb)
                .onSuccess { (extra: S.R.TExtrinsic.SigningPayload.Extra) in
                    self.signAndSubmit(call: call, extra: extra, with: account, timeout: timeout, cb)
                }
        }
    }
}

extension SubstrateExtrinsicApi where S.R: DefaultExtrinsicExtraProvider {
    public func signAndSubmit(
        call: AnyCall, with account: S.R.TAccountId, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        signAndSubmit(call: call, with: account, options: (), timeout: timeout, cb)
    }
}
