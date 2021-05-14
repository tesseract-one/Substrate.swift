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

public class Keychain {
    public private(set) var keyPairs: Array<KeyPair> = []
    
    public func publicKeys(format: Ss58AddressFormat) -> Array<PublicKey> {
        keyPairs.map { $0.pubKey(format: format) }
    }
    
    public func keyPair(for account: PublicKey) -> KeyPair? {
        keyPairs.first { $0.typeId == account.typeId && $0.rawPubKey == account.bytes }
    }
    
    public func keyPairs(for typeId: CryptoTypeId) -> [KeyPair] {
        keyPairs.filter { $0.typeId == typeId }
    }
    
    public func add(_ pair: KeyPair) {
        keyPairs.append(pair)
    }
}
