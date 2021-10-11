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
    
    public init(accountId: S.TAccountId) {
        self.accountId = accountId
        self._hash = nil
    }
}

extension SystemAccountStorageKey: MapStorageKey {
    public typealias Module = SystemModule<S>
    public typealias K = S.TAccountId
    public typealias Value = AccountInfo<S>
    
    public static var FIELD: String { "Account" }
    
    public var key: K? { accountId }
    public var hash: Data? { _hash }
    
    public init(key: S.TAccountId) {
        self.init(accountId: key)
    }
    
    public init(key: S.TAccountId?, hash: Data) {
        self.accountId = key
        self._hash = hash
    }
}

public struct SystemAccountStorageKey<S: System> {
    /// Account to retrieve the `AccountInfo<S>` for.
    public let accountId: S.TAccountId?
    /// Hash for decoded key
    private let _hash: Data?
    
    public init(accountId: S.TAccountId) {
        self.accountId = accountId
        self._hash = nil
    }
}

extension SystemAccountStorageKey: MapStorageKey {
    public typealias Module = SystemModule<S>
    public typealias K = S.TAccountId
    public typealias Value = AccountInfo<S>
    
    public static var FIELD: String { "Account" }
    
    public var key: K? { accountId }
    public var hash: Data? { _hash }
    
    public init(key: S.TAccountId) {
        self.init(accountId: key)
    }
    
    public init(key: S.TAccountId?, hash: Data) {
        self.accountId = key
        self._hash = hash
    }
}
