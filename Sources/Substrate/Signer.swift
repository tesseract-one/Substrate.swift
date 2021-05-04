//
//  Signer.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public typealias SSignerResult<V, R: Runtime> = Result<V, SubstrateSignerError<R>>
public typealias SSignerCallback<V, R: Runtime> = (SSignerResult<V, R>) -> Void

public typealias SSigningPayload<C: AnyCall, R: Runtime> = ExtrinsicSigningPayload<C, R.TExtrinsicExtra>
public typealias SExtrinsic<C: AnyCall, R: Runtime> = Extrinsic<R.TAddress, C, R.TSignature, R.TExtrinsicExtra>

public protocol SubstrateSigner {
    // Get list of accounts
    func accounts<R: Runtime>(with runtime: R.Type, _ cb: @escaping SSignerCallback<[R.TAccountId], R>)
    
    // Sign extrinsic payload
    func sign<C: AnyCall, R: Runtime>(
        payload: SSigningPayload<C, R>,
        in runtime: R.Type,
        with account: R.TAccountId,
        _ cb: @escaping SSignerCallback<SExtrinsic<C, R>, R>
    )
}

public enum SubstrateSignerError<R: Runtime>: Error {
    case accountNotFound(R.TAccountId)
    case cantBeConnected
    case cancelledByUser
    case unknown(Error)
}
