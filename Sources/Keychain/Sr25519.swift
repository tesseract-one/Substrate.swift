//
//  Sr25519.swift
//  
//
//  Created by Yehor Popovych on 06.05.2021.
//

import Foundation
import Substrate
import Sr25519
import Bip39

private typealias SRKeyPair = Sr25519.Sr25519KeyPair
private typealias SRSeed = Sr25519.Sr25519Seed
private typealias SRSignature = Sr25519.Sr25519Signature
private typealias SRChainCode = Sr25519.Sr25519ChainCode
private typealias SRPublicKey = Sr25519.Sr25519PublicKey

#if COCOAPODS
public typealias SBSRPublicKey = Substrate.Sr25519PublicKey
public typealias SBSRSignature = Substrate.Sr25519Signature
#else
public typealias SBSRPublicKey = SubstratePrimitives.Sr25519PublicKey
public typealias SBSRSignature = SubstratePrimitives.Sr25519Signature
#endif

public struct Sr25519KeyPair: KeyPair {
    private let keyPair: SRKeyPair
    
    public var rawPubKey: Data { keyPair.publicKey.raw }
    public var typeId: CryptoTypeId { .sr25519 }
    
    public init(phrase: String, password: String? = nil) throws {
        let mnemonic = try Mnemonic(mnemonic: phrase.components(separatedBy: " "))
        let seed = mnemonic.seed(password: password ?? "", wordlist: .english)
        try self.init(seed: Data(seed))
    }
    
    public init(seed: Data) throws {
        try self.init(keyPair: SRKeyPair(seed: SRSeed(raw: seed.prefix(SRSeed.size))))
    }
    
    public init() {
        try! self.init(seed: Data(SubstrateKeychainRandom.bytes(count: SRSeed.size)))
    }
    
    public func pubKey(format: Ss58AddressFormat) -> PublicKey {
        try! SBSRPublicKey(bytes: keyPair.publicKey.raw, format: format)
    }
    
    public func sign(message: Data) throws -> Data {
        let hash = HBlake2b256.hasher.hash(data: message)
        return keyPair.sign(message: hash).raw
    }
    
    public func verify(message: Data, signature: Data) throws -> Bool {
        let hash = HBlake2b256.hasher.hash(data: message)
        return try keyPair.verify(message: hash, signature: SRSignature(raw: signature))
    }
    
    public static var seedLength: Int = SRSeed.size
    
    private init(keyPair: SRKeyPair) {
        self.keyPair = keyPair
    }
}

extension Sr25519KeyPair: Derivable {
    public func derive(path: [DeriveJunction]) throws -> Sr25519KeyPair {
        let kp = try path.reduce(keyPair) { (pair, cmp) in
            try pair.derive(chainCode: SRChainCode(raw: cmp.bytes), hard: cmp.isHard)
        }
        return Self(keyPair: kp)
    }
}

extension SBSRPublicKey: Derivable {
    public func derive(path: [DeriveJunction]) throws -> SBSRPublicKey {
        let pub = try path.reduce(SRPublicKey(raw: bytes)) { (pub, cmp) in
            guard cmp.isSoft else { throw DeriveError.publicHardPath }
            return try pub.derive(chainCode: SRChainCode(raw: cmp.bytes))
        }
        return try SBSRPublicKey(bytes: pub.raw, format: format)
    }
}


extension SBSRPublicKey {
    public func verify(signature: SBSRSignature, message: Data) -> Bool {
        guard let pub = try? SRPublicKey(raw: self.bytes) else {
            return false
        }
        guard let sig = try? SRSignature(raw: signature.signature) else {
            return false
        }
        return pub.verify(message: message, signature: sig)
    }
}
