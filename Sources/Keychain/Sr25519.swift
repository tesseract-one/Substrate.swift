//
//  Sr25519.swift
//  
//
//  Created by Yehor Popovych on 06.05.2021.
//

import Foundation
import Substrate
import Sr25519

public struct Sr25519KeyPair: KeyPair {    
    private let keyPair: Sr25519.KeyPair
    
    public var rawPubKey: Data { keyPair.publicKey.key }
    public var typeId: CryptoTypeId { .sr25519 }
    
    public init(phrase: String, password: String?) throws {
        let seed = try Mnemonic(phrase: phrase.components(separatedBy: " "), passphrase: password ?? "").seed()
        try self.init(seed: Data(seed))
    }
    
    public init(seed: Data) throws {
        try self.init(keyPair: Sr25519.KeyPair(seed: Sr25519.Seed(seed: seed)))
    }
    
    public func pubKey(format: Ss58AddressFormat) -> PublicKey {
        try! Sr25519PublicKey(bytes: keyPair.publicKey.key, format: format)
    }
    
    public func sign(message: Data) throws -> Data {
        keyPair.sign(message: message).data
    }
    
    public func verify(message: Data, signature: Data) throws -> Bool {
        try keyPair.verify(message: message, signature: Sr25519.Signature(signature: signature))
    }
    
    public static var seedLength: Int = Seed.size
    
    private init(keyPair: Sr25519.KeyPair) {
        self.keyPair = keyPair
    }
}

extension Sr25519KeyPair: Derivable {
    public func derive(path: [DeriveJunction]) throws -> Sr25519KeyPair {
        let kp = try path.reduce(keyPair) { (pair, cmp) in
            try pair.derive(chainCode: Sr25519.ChainCode(code: cmp.bytes), hard: cmp.isHard)
        }
        return Self(keyPair: kp)
    }
}

extension Sr25519PublicKey: Derivable {
    public func derive(path: [DeriveJunction]) throws -> Sr25519PublicKey {
        let pub = try path.reduce(Sr25519.PublicKey(data: bytes)) { (pub, cmp) in
            guard cmp.isSoft else { throw DeriveError.publicHardPath }
            return try pub.derive(chainCode: Sr25519.ChainCode(code: cmp.bytes))
        }
        return try Sr25519PublicKey(bytes: pub.key, format: format)
    }
}
