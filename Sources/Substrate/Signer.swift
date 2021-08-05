//
//  Signer.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public typealias SSignerResult<V> = Result<V, SubstrateSignerError>
public typealias SSignerCallback<V> = (SSignerResult<V>) -> Void

public protocol SubstrateSigner {
    // Get list of accounts
    func accounts<R: Runtime>(
        with runtime: R.Type,
        format: Ss58AddressFormat,
        _ cb: @escaping SSignerCallback<AccountList<R>>
    )
    
    // Sign extrinsic payload
    func sign<R: Runtime>(
        payload: R.TExtrinsic.SigningPayload,
        with account: PublicKey,
        in runtime: R.Type,
        registry: TypeRegistryProtocol,
        _ cb: @escaping SSignerCallback<R.TExtrinsic>
    )
}

public enum SubstrateSignerError: Error {
    case accountNotFound(PublicKey)
    case badPayload(error: String)
    case cantCreateAddress(error: String)
    case cantCreateSignature(error: String)
    case cantCreateExtrinsic(error: String)
    case cantBeConnected
    case cancelledByUser
    case unknown(error: String)
}
