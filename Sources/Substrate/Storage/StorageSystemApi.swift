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
        accountId: S.R.TAccountId, at: S.R.THash? = nil, timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<AccountInfo<S.R>>
    ) {
        substrate.rpc.state.getStorage(
            for: SystemAccountStorageKey(accountId: accountId),
            at: at, timeout: timeout, cb
        )
    }
    
    public func accounts(
        count: UInt32, from accountId: S.R.TAccountId? = nil, hash: S.R.THash? = nil,
        timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<AccountInfo<S.R>>
    ) {
        
    }
}

extension SubstrateStorageApiRegistry where S.R: System {
    public var system: SubstrateStorageSystemApi<S> { getStorageApi(SubstrateStorageSystemApi<S>.self) }
}
