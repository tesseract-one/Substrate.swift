//
//  ExtrinsicExtraProvider.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public protocol ExtrinsicExtraProvider: Balances {
    associatedtype TExtraOptions
    
    static func createExtra<S>(
        accountId: TAccountId,
        options: TExtraOptions,
        timeout: TimeInterval,
        substrate: S,
        cb: @escaping SRpcApiCallback<TExtrinsic.SigningPayload.Extra>
    ) where S: SubstrateProtocol, S.R == Self
}

public protocol DefaultExtrinsicExtraProvider: ExtrinsicExtraProvider
    where TExtraOptions == Void, TExtrinsic.SigningPayload.Extra == DefaultExtrinsicExtra<Self> {}

extension DefaultExtrinsicExtraProvider {
    public static func createExtra<S>(
        accountId: TAccountId, options: TExtraOptions, timeout: TimeInterval, substrate: S,
        cb: @escaping SRpcApiCallback<TExtrinsic.SigningPayload.Extra>
    ) where Self == S.R, S : SubstrateProtocol {
        nonce(accountId: accountId, timeout: timeout, substrate: substrate) { res in
            let result = res
                .map {
                    TExtrinsic.SigningPayload.Extra.create(
                        specVersion: substrate.runtimeVersion.specVersion,
                        txVersion: substrate.runtimeVersion.transactionVersion,
                        nonce: $0, genesisHash: substrate.genesisHash
                    )
                }
            cb(result)
        }
    }
    
    private static func nonce<S>(
        accountId: TAccountId, timeout: TimeInterval, substrate: S,
        _ cb: @escaping SRpcApiCallback<TIndex>
    ) where Self == S.R, S : SubstrateProtocol {
        substrate.query.system.accounts.get(key: accountId) {
            cb($0.map { $0.nonce })
        }
    }
}
