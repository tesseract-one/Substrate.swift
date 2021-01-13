//
//  BalancesStorage.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation

public struct TotalIssuanceStorageKey<B: Balances> {}

extension TotalIssuanceStorageKey: StorageKey {
    public typealias Value = B.TBalance
    public typealias Module = BalancesModule<B>
    
    public static var FIELD: String { "TotalIssuance" }
    
    public var path: [ScaleDynamicEncodable] { [] }
}
