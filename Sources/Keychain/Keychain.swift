//
//  Keychain.swift
//  
//
//  Created by Yehor Popovych on 26.04.2021.
//

import Foundation
import Substrate
import Sr25519

public typealias SubstrateKeychainRandom = Sr25519SecureRandom

public protocol KeychainDelegate: AnyObject {
    func account(type: KeyTypeId, keys: [any PublicKey]) async -> (any PublicKey)?
}

public class Keychain {
    public private(set) var keyPairs: Array<any KeyPair>
    public weak var delegate: (any KeychainDelegate)!
    
    public init(delegate: any KeychainDelegate) {
        self.keyPairs = []
        self.delegate = delegate
    }
    
    public var publicKeys: Array<any PublicKey> {
        keyPairs.map { $0.pubKey }
    }
    
    public func keyPair(for account: any PublicKey) -> KeyPair? {
        keyPairs.first { $0.algorithm == account.algorithm && $0.pubKey.raw == account.raw }
    }
    
    public func keyPairs(for algorithm: CryptoTypeId) -> [KeyPair] {
        keyPairs.filter { $0.algorithm == algorithm }
    }
    
    public func add(_ pair: KeyPair) {
        keyPairs.append(pair)
    }
}
