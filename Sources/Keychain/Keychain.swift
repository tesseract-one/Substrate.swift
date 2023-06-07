//
//  Keychain.swift
//  
//
//  Created by Yehor Popovych on 26.04.2021.
//

import Foundation
import Sr25519
#if !COCOAPODS
import Substrate
#endif

public typealias SubstrateKeychainRandom = Sr25519SecureRandom

public protocol KeychainDelegate: AnyObject {
    func account(type: KeyTypeId, keys: [any PublicKey]) async -> (any PublicKey)?
}

public class KeychainDelegateFirstFound: KeychainDelegate {
    public init() {}
    public func account(type: KeyTypeId, keys: [any PublicKey]) async -> (any PublicKey)? {
        keys.first
    }
}

public class Keychain {
    public let keyPairs: Synced<Array<any KeyPair>>
    public weak var delegate: (any KeychainDelegate)!
    
    public init(keyPairs: Array<any KeyPair> = [],
                delegate: any KeychainDelegate = KeychainDelegateFirstFound()) {
        self.keyPairs = Synced(value: keyPairs)
        self.delegate = delegate
    }
    
    public var publicKeys: Array<any PublicKey> {
        keyPairs.sync { $0.map { $0.pubKey } }
    }
    
    public func keyPair(for account: any PublicKey) -> (any KeyPair)? {
        keyPairs.sync { $0.first { $0.algorithm == account.algorithm && $0.pubKey.raw == account.raw } }
    }
    
    public func keyPairs(for algorithm: CryptoTypeId) -> [any KeyPair] {
        keyPairs.sync { $0.filter { $0.algorithm == algorithm } }
    }
    
    public func add(_ pair: any KeyPair) {
        keyPairs.sync { $0.append(pair) }
    }
}
