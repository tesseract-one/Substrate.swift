//
//  KeyPair.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import Bip39
#if !COCOAPODS
import Substrate
#endif

public protocol KeyPair {
    var algorithm: CryptoTypeId { get }
    var pubKey: any PublicKey { get }
    var raw: Data { get }
    
    init()
    init(phrase: String, password: String?, wordlist: Wordlist) throws
    init(seed: Data) throws
    init(raw: Data) throws
    
    func sign(message: Data) -> any Signature
    func verify(message: Data, signature: any Signature) -> Bool
    
    static var seedLength: Int { get }
}

public extension KeyPair {
    init(phrase: String, password: String? = nil, wordlist: Wordlist = .english) throws {
        let mnemonic: Mnemonic
        do {
            mnemonic = try Mnemonic(mnemonic: phrase.components(separatedBy: " "))
        } catch {
            throw KeyPairError(error: error)
        }
        let seed = mnemonic.substrate_seed(password: password ?? "")
        try self.init(seed: Data(seed))
    }
    
    @inlinable
    func account<A: AccountId>(runtime: any Runtime) throws -> A {
        try pubKey.account(runtime: runtime)
    }
    
    @inlinable
    func address<A: Address>(runtime: any Runtime) throws -> A {
        try pubKey.address(runtime: runtime)
    }
    
    @inlinable
    func account<R: RootApi>(in api: R) throws -> R.RC.TAccountId {
        try pubKey.account(in: api)
    }
    
    @inlinable
    func address<R: RootApi>(in api: R) throws -> R.RC.TAddress {
        try pubKey.address(in: api)
    }
}
