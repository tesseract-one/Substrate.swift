//
//  Keychain.swift
//  
//
//  Created by Yehor Popovych on 26.04.2021.
//

import Foundation
import Sr25519
import Substrate

public typealias Random = Sr25519SecureRandom

public enum KeychainDelegateResponse {
    case cancelled
    case noAccount
    case account(any PublicKey)
}

public protocol KeychainDelegate: AnyObject {
    func account(in keychain: Keychain,
                 for type: KeyTypeId,
                 algorithms algos: [CryptoTypeId]) async -> KeychainDelegateResponse
}

public class KeychainDelegateFirstFound: KeychainDelegate {
    public init() {}
    public func account(in keychain: Keychain,
                        for type: KeyTypeId,
                        algorithms algos: [CryptoTypeId]) async -> KeychainDelegateResponse
    {
        let typed = keychain.publicKeys(for: type).first { algos.contains($0.algorithm) }
        if let t = typed {
            return .account(t)
        }
        if let t = keychain.publicKeys().first(where: { algos.contains($0.algorithm) }) {
            return .account(t)
        }
        return .noAccount
    }
}

public class Keychain {
    public let keyPairs: Synced<Dictionary<KeyTypeId?, Array<any KeyPair>>>
    public weak var delegate: (any KeychainDelegate)!
    
    public init(keyPairs: Array<(KeyTypeId?, any KeyPair)> = [],
                delegate: any KeychainDelegate = KeychainDelegateFirstFound()) {
        let kps = keyPairs.reduce(Dictionary<KeyTypeId?, Array<any KeyPair>>()) { dict, kp in
            var dict = dict
            var kps = dict[kp.0] ?? []
            kps.append(kp.1)
            dict[kp.0] = kps
            return dict
        }
        self.keyPairs = Synced(value: kps)
        self.delegate = delegate
    }
    
    public func keyPairs(for type: KeyTypeId? = nil,
                         algorithm: CryptoTypeId? = nil) -> [any KeyPair]
    {
        keyPairs.sync { kps in
            let pairs = type != nil ? (kps[type] ?? []) : kps.values.flatMap { $0 }
            return algorithm == nil ? pairs : pairs.filter { $0.algorithm == algorithm }
        }
    }
    
    public func publicKeys(for type: KeyTypeId? = nil,
                           algorithm: CryptoTypeId? = nil) -> [any PublicKey]
    {
        keyPairs(for: type, algorithm: algorithm).map { $0.pubKey }
    }
    
    public func keyPair(for account: any PublicKey) -> (any KeyPair)? {
        keyPairs.sync {
            $0.values.reduce(nil) { val, arr in
                val != nil ? val : arr.first {
                    $0.algorithm == account.algorithm && $0.pubKey.raw == account.raw
                }
            }
        }
    }
    
    public func add(_ pair: any KeyPair, for type: KeyTypeId? = nil) {
        keyPairs.mutate {
            var kps = $0[type] ?? []
            kps.append(pair)
            $0[type] = kps
        }
    }
}
