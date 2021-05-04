//
//  Keychain.swift
//  
//
//  Created by Yehor Popovych on 26.04.2021.
//

import Foundation
import Substrate

public protocol PublicKey {
    var bytes: Data { get }
    var algorithm: KeyPairAlgorithm { get }
    
    func account<R: Runtime>(for runtime: R.Type) throws -> R.TAccountId
}

public protocol KeyPair {
    var pubKey: PublicKey { get }
    var algorithm: KeyPairAlgorithm { get }
    
    func sign(message: Data) throws -> Data
    func verify(message: Data, signature: Data) throws -> Bool
}


public class Keychain {
    private var _keyPairs: Array<KeyPair> = []
    public var keyPairs: Array<KeyPair> { _keyPairs }
    
    public var publicKeys: Array<PublicKey> {
        _keyPairs.map { $0.pubKey }
    }
    
    public func accounts<R: Runtime>(for runtime: R.Type) throws -> [R.TAccountId] {
        try publicKeys.map { try $0.account(for: runtime) }
    }
    
//    public func keyPair<R: Runtime>(for account: R.)
    
    public func add(pair: KeyPair) {
        _keyPairs.append(pair)
    }
}
