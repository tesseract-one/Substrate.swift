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
    
    public var accounts: StorageApiEntry<S, SystemAccountStorageKey<S.R>> {
        StorageApiEntry(substrate: substrate)
    }
    
    public var 
}

extension SubstrateStorageApiRegistry where S.R: System {
    public var system: SubstrateStorageSystemApi<S> { getStorageApi(SubstrateStorageSystemApi<S>.self) }
}
