//
//  Mnemonic+Substrate.swift
//  
//
//  Created by Yehor Popovych on 14.05.2021.
//

import Foundation
import Bip39
import UncommonCrypto

extension Mnemonic {
    public func substrate_seed(password: String = "") -> [UInt8] {
        let salt = Array(("mnemonic"+password).utf8)
        return try! PBKDF2.derive(type: .sha512, password: self.entropy, salt: salt, iterations: 2048, keyLength: 64)
    }
}
