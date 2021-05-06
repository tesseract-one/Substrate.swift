//
//  Keychain.swift
//  
//
//  Created by Yehor Popovych on 26.04.2021.
//

import Foundation
import Substrate

public class Keychain {
    private var _keyPairs: Array<KeyPair> = []
    public var keyPairs: Array<KeyPair> { _keyPairs }
    
    public func publicKeys(format: Ss58AddressFormat) -> Array<PublicKey> {
        _keyPairs.map { $0.pubKey(format: format) }
    }
    
    public func keyPair(for account: PublicKey) -> KeyPair? {
        _keyPairs.first { $0.typeId == account.typeId && $0.rawPubKey == account.bytes }
    }
    
    public func keyPairs(for typeId: CryptoTypeId) -> [KeyPair] {
        _keyPairs.filter { $0.typeId == typeId }
    }
    
    public func add(pair: KeyPair) {
        _keyPairs.append(pair)
    }
}
