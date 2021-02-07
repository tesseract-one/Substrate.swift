//
//  StorageSystemApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public struct SubstrateStorageSystemApi<S: SubstrateProtocol>: SubstrateStorageApi {
    public weak var substrate: S!

    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func accountInfo(
        accountId: S.R.TAccountId, hash: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<AccountInfo<S.R>>
    ) {
        substrate.rpc.state.getStorage(
            for: SystemAccountStorageKey(accountId: accountId),
            hash: hash, timeout: timeout, cb
        )
    }
}

extension SubstrateStorageApiRegistry where S.R: System {
    public var system: SubstrateStorageSystemApi<S> { getStorageApi(SubstrateStorageSystemApi<S>.self) }
}
