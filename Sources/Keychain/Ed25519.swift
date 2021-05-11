//
//  Ed25519.swift
//  
//
//  Created by Yehor Popovych on 09.05.2021.
//

import Foundation
import Bip39
import ScaleCodec

#if COCOAPODS
import Sr25519

private typealias EDKeyPair = Sr25519.Ed25519KeyPair
private typealias EDSeed = Sr25519.Ed25519Seed
private typealias EDSignature = Sr25519.Ed25519Signature
private typealias EDPublicKey = Sr25519.Ed25519PublicKey

public typealias SBEDPublicKey = Substrate.Ed25519PublicKey

#else
import Ed25519
import Sr25519
import Substrate

private typealias EDKeyPair = Ed25519.Ed25519KeyPair
private typealias EDSeed = Ed25519.Ed25519Seed
private typealias EDSignature = Ed25519.Ed25519Signature
private typealias EDPublicKey = Ed25519.Ed25519PublicKey

public typealias SBEDPublicKey = SubstratePrimitives.Ed25519PublicKey
#endif

public struct Ed25519KeyPair: KeyPair {
    private let keyPair: EDKeyPair
    
    public var rawPubKey: Data { keyPair.publicKey.raw }
    public var typeId: CryptoTypeId { .ed25519 }
    
    public init(phrase: String, password: String? = nil) throws {
        let mnemonic = try Mnemonic(mnemonic: phrase.components(separatedBy: " "))
        let seed = mnemonic.seed(password: password ?? "", wordlist: .english)
        try self.init(seed: Data(seed))
    }
    
    public init(seed: Data) throws {
        try self.init(keyPair: EDKeyPair(seed: EDSeed(raw: seed.prefix(EDSeed.size))))
    }
    
    public func pubKey(format: Ss58AddressFormat) -> PublicKey {
        try! SBEDPublicKey(bytes: keyPair.publicKey.raw, format: format)
    }
    
    public func sign(message: Data) throws -> Data {
        keyPair.sign(message: message).raw
    }
    
    public func verify(message: Data, signature: Data) throws -> Bool {
        try keyPair.verify(message: message, signature: EDSignature(raw: signature))
    }
    
    public static var seedLength: Int = EDSeed.size
    
    private init(keyPair: EDKeyPair) {
        self.keyPair = keyPair
    }
}

extension Ed25519KeyPair: Derivable {
    public func derive(path: [DeriveJunction]) throws -> Ed25519KeyPair {
        let kp = try path.reduce(keyPair) { (pair, cmp) in
            guard cmp.isHard else { throw DeriveError.softDeriveIsNotSupported }
            let data = try! SCALE.default.encode(STuple3("Ed25519HDKD", keyPair.privateRaw, cmp.bytes))
            let hash = HBlake2b256.hasher.hash(data: data)
            return try EDKeyPair(seed: EDSeed(raw: hash))
        }
        return Self(keyPair: kp)
    }
}

//extension SBEDPublicKey: Derivable {
//    public func derive(path: [DeriveJunction]) throws -> SBEDPublicKey {
//        throw DeriveError.publicDeriveIsNotSupported
//    }
//}
