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
public typealias SBEDSignature = Substrate.Ed25519Signature
#else
import Ed25519
import Sr25519
import Substrate

private typealias EDKeyPair = Ed25519.Ed25519KeyPair
private typealias EDSeed = Ed25519.Ed25519Seed
private typealias EDSignature = Ed25519.Ed25519Signature
private typealias EDPublicKey = Ed25519.Ed25519PublicKey

public typealias SBEDPublicKey = SubstratePrimitives.Ed25519PublicKey
public typealias SBEDSignature = SubstratePrimitives.Ed25519Signature
#endif

public struct Ed25519KeyPair {
    private let keyPair: EDKeyPair
    
    private init(keyPair: EDKeyPair) {
        self.keyPair = keyPair
    }
    
    public func publicKey(format: Ss58AddressFormat) -> SBEDPublicKey {
        try! SBEDPublicKey(bytes: keyPair.publicKey.raw, format: format)
    }
    
    fileprivate static func convertError<T>(_ cb: () throws -> T) throws -> T {
        do {
            return try cb()
        } catch let e as Ed25519Error {
            switch e {
            case .badKeyPairLength, .badPrivateKeyLength:
                throw KeyPairError.native(error: .badPrivateKey)
            case .badPublicKeyLength:
                throw KeyPairError.input(error: .publicKey)
            case .badSeedLength:
                throw KeyPairError.input(error: .seed)
            case .badSignatureLength:
                throw KeyPairError.input(error: .signature)
            }
        } catch {
            throw KeyPairError(error: error)
        }
    }
}

extension Ed25519KeyPair: KeyPair {
    public var rawPubKey: Data { keyPair.publicKey.raw }
    public var typeId: CryptoTypeId { .ed25519 }
    
    public init(phrase: String, password: String? = nil) throws {
        let mnemonic = try Self.convertError {
            try Mnemonic(mnemonic: phrase.components(separatedBy: " "))
        }
        let seed = mnemonic.substrate_seed(password: password ?? "")
        try self.init(seed: Data(seed))
    }
    
    public init(seed: Data) throws {
        let kpSeed = try Self.convertError {
            try EDSeed(raw: seed.prefix(EDSeed.size))
        }
        self.init(keyPair: EDKeyPair(seed: kpSeed))
    }
    
    public init() {
        try! self.init(seed: Data(SubstrateKeychainRandom.bytes(count: EDSeed.size)))
    }
    
    public func pubKey(format: Ss58AddressFormat) -> PublicKey {
        publicKey(format: format)
    }
    
    public func sign(message: Data) -> Data {
        return keyPair.sign(message: message).raw
    }
    
    public func verify(message: Data, signature: Data) -> Bool {
        guard let sig = try? EDSignature(raw: signature) else {
            return false
        }
        return keyPair.verify(message: message, signature: sig)
    }
    
    public static var seedLength: Int = EDSeed.size
}

extension Ed25519KeyPair: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> Ed25519KeyPair {
        let kp = try path.reduce(keyPair) { (pair, cmp) in
            guard cmp.isHard else { throw KeyPairError.derive(error: .softDeriveIsNotSupported) }
            let encoder = SCALE.default.encoder()
            try encoder.encode("Ed25519HDKD")
            try encoder.encode(keyPair.privateRaw, .fixed(UInt(EDKeyPair.secretSize)))
            try encoder.encode(cmp.bytes, .fixed(UInt(PathComponent.size)))
            let hash = HBlake2b256.hasher.hash(data: encoder.output)
            let seed = try Self.convertError { try EDSeed(raw: hash) }
            return EDKeyPair(seed: seed)
        }
        return Self(keyPair: kp)
    }
}

extension SBEDPublicKey: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> SBEDPublicKey {
        throw KeyPairError.derive(error: .softDeriveIsNotSupported)
    }
}

extension SBEDPublicKey {
    public func verify(signature: SBEDSignature, message: Data) -> Bool {
        guard let pub = try? EDPublicKey(raw: self.bytes) else {
            return false
        }
        guard let sig = try? EDSignature(raw: signature.signature) else {
            return false
        }
        return pub.verify(message: message, signature: sig)
    }
}
