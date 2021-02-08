//
//  SystemStorage.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct SystemAccountStorageKey<S: System> {
    /// Account to retrieve the `AccountInfo<S>` for.
    public let accountId: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(accountId: S.TAccountId?) {
        self.accountId = accountId
        self._hash = nil
    }
}

extension SystemAccountStorageKey: MapStorageKey {
    public typealias Module = SystemModule<S>
    public typealias K = S.TAccountId
    public typealias Value = AccountInfo<S>
    
    public static var FIELD: String { "Account" }
    
    public var path: K? { accountId }
    public var hash: Data? { _hash }
    
    public init(path: S.TAccountId?, hash: Data) {
        self.accountId = path
        self._hash = hash
    }
}
