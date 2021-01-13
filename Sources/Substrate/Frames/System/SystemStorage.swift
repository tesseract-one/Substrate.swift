//
//  SystemStorage.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation

public struct SystemAccountStorageKey<S: System> {
    /// Account to retrieve the `AccountInfo<S>` for.
    public let accountId: S.TAccountId
}

extension SystemAccountStorageKey: StorageKey {
    public typealias Module = SystemModule<S>
    public typealias Value = AccountInfo<S>
    
    public static var FIELD: String { "Account" }
    
    public var path: [ScaleDynamicEncodable] { return [accountId] }
}
