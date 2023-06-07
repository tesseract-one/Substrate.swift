//
//  KeyPair.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import Substrate

public protocol KeyPair {
    var algorithm: CryptoTypeId { get }
    var pubKey: any PublicKey { get }
    var raw: Data { get }
    
    init()
    init(phrase: String, password: String?) throws
    init(seed: Data) throws
    init(raw: Data) throws
    
    func sign(message: Data) -> any Signature
    func verify(message: Data, signature: any Signature) -> Bool
    
    static var seedLength: Int { get }
}
