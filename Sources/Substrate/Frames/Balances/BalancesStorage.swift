//
//  BalancesStorage.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation

public struct BalancesTotalIssuanceStorageKey<B: Balances> {
    public init() {}
}

extension BalancesTotalIssuanceStorageKey: PlainStorageKey {
    public typealias Value = B.TBalance
    public typealias Module = BalancesModule<B>
    
    public static var FIELD: String { "TotalIssuance" }
}
