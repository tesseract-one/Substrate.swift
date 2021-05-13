//
//  KeyPair.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import Substrate

public protocol KeyPair {
    var typeId: CryptoTypeId { get }
    var rawPubKey: Data { get }
    
    init()
    init(phrase: String, password: String?) throws
    init(seed: Data) throws
    
    func pubKey(format: Ss58AddressFormat) -> PublicKey
    
    func sign(message: Data) -> Data
    func verify(message: Data, signature: Data) -> Bool
    
    static var seedLength: Int { get }
}
