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

public extension KeyPair {
    @inlinable
    func account<A: AccountId>(runtime: any Runtime) throws -> A {
        try pubKey.account(runtime: runtime)
    }
    
    @inlinable
    func address<A: Address>(runtime: any Runtime) throws -> A {
        try pubKey.address(runtime: runtime)
    }
    
    @inlinable
    func account<S: SomeSubstrate>(in substrate: S) throws -> S.RC.TAccountId {
        try pubKey.account(in: substrate)
    }
    
    @inlinable
    func address<S: SomeSubstrate>(in substrate: S) throws -> S.RC.TAddress {
        try pubKey.address(in: substrate)
    }
}
