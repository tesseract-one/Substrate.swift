//
//  ExtrinsicApi+Sign.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

extension SubstrateExtrinsicApi where S.R: Session {
    public func accounts(_ cb: @escaping SExtrinsicApiCallback<AccountList<S.R>, S.R>) {
        guard let signer = substrate.signer else {
            cb(.failure(.dontHaveSigner))
            return
        }
        signer.accounts(with: S.R.self, format: substrate.properties.ss58Format) {
            cb($0.mapError(SubstrateExtrinsicApiError<S.R>.signer))
        }
    }
    
    public func sign<C: AnyCall>(
        call: C, extra: S.R.TExtrinsicExtra, with account: S.R.TAccountId,
        _ cb: @escaping SExtrinsicApiCallback<SExtrinsic<C, S.R>, S.R>
    ) {
        guard let signer = substrate.signer else {
            cb(.failure(.dontHaveSigner))
            return
        }
        guard account.format == substrate.properties.ss58Format else {
            cb(.failure(.badSs58Format(format: account.format, expected: substrate.properties.ss58Format)))
            return
        }
        do {
            let payload = try SSigningPayload<C, S.R>(call: call, extra: extra)
            signer.sign(payload: payload, with: account, in: S.R.self, registry: substrate.registry) { res in
                cb(res.mapError(SubstrateExtrinsicApiError<S.R>.signer))
            }
        } catch {
            cb(.failure(.payload(error: error)))
        }
    }
    
    public func signAndSubmit<C: AnyCall>(
        call: C, extra: S.R.TExtrinsicExtra, with account: S.R.TAccountId,
        timeout: TimeInterval? = nil, _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        self.sign(call: call, extra: extra, with: account) {
            switch $0 {
            case .failure(let err): cb(.failure(err))
            case .success(let extrinsic): self.submit(extrinsic: extrinsic, timeout: timeout, cb)
            }
        }
    }
}

extension SubstrateExtrinsicApi where S.R.TExtrinsicExtra: SignedExtrinsicExtra, S.R.TExtrinsicExtra.S == S.R, S.R: Session {
    public func createExtra(
        accountId: S.R.TAccountId, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.TExtrinsicExtra, S.R>
    ) {
        nonce(accountId: accountId, timeout: timeout) { res in
            let result = res
                .map {
                    S.R.TExtrinsicExtra.create(
                        specVersion: self.substrate.runtimeVersion.specVersion,
                        txVersion: self.substrate.runtimeVersion.transactionVersion,
                        nonce: $0, genesisHash: self.substrate.genesisHash
                    )
                }
            cb(result)
        }
    }
    
    public func signAndSubmit<C: AnyCall>(
        call: C, with account: S.R.TAccountId, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        createExtra(accountId: account, timeout: timeout) {
            switch $0 {
            case .failure(let err): cb(.failure(err))
            case .success(let extra): self.signAndSubmit(call: call, extra: extra, with: account, cb)
            }
        }
    }
}
