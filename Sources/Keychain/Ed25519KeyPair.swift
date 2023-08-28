//
//  Ed25519.swift
//  
//
//  Created by Yehor Popovych on 09.05.2021.
//

import Foundation
import Bip39
import ScaleCodec
import Substrate

#if COCOAPODS
import Sr25519
private typealias EDKeyPair = Sr25519.Ed25519KeyPair
private typealias EDSeed = Sr25519.Ed25519Seed
private typealias EDSignature = Sr25519.Ed25519Signature
private typealias EDPublicKey = Sr25519.Ed25519PublicKey
#else
import Ed25519
private typealias EDKeyPair = Ed25519.Ed25519KeyPair
private typealias EDSeed = Ed25519.Ed25519Seed
private typealias EDSignature = Ed25519.Ed25519Signature
private typealias EDPublicKey = Ed25519.Ed25519PublicKey
#endif


public struct Ed25519KeyPair: Equatable, Hashable {
    private let _keyPair: EDKeyPair
    public let publicKey: Substrate.Ed25519PublicKey
    
    private init(keyPair: EDKeyPair) {
        self._keyPair = keyPair
        self.publicKey = try! Substrate.Ed25519PublicKey(keyPair.publicKey.raw)
    }
    
    fileprivate static func convertError<T>(_ cb: () throws -> T) throws -> T {
        do {
            return try cb()
        } catch let e as Ed25519Error {
            switch e {
            case .badKeyPairLength:
                throw KeyPairError.native(error: .badPrivateKey)
            case .badPrivateKeyLength:
                throw KeyPairError.input(error: .privateKey)
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
    public var raw: Data { _keyPair.raw }
    public var pubKey: any PublicKey { publicKey }
    public var algorithm: CryptoTypeId { .ed25519 }
    
    public init(seed: Data) throws {
        let kpSeed = try Self.convertError {
            try EDSeed(raw: seed.prefix(EDSeed.size))
        }
        self.init(keyPair: EDKeyPair(seed: kpSeed))
    }
    
    public init() {
        try! self.init(seed: Data(Random.bytes(count: EDSeed.size)))
    }
    
    public init(raw: Data) throws {
        let kp = try Self.convertError {
            try EDKeyPair(raw: raw)
        }
        self.init(keyPair: kp)
    }
    
    public func sign(message: Data) -> any Signature {
        return try! Substrate.Ed25519Signature(raw: _keyPair.sign(message: message).raw)
    }
    
    public func verify(message: Data, signature: any Signature) -> Bool {
        guard signature.algorithm == self.algorithm else {
            return false
        }
        guard let sig = try? EDSignature(raw: signature.raw) else {
            return false
        }
        return _keyPair.verify(message: message, signature: sig)
    }
    
    public static var seedLength: Int = EDSeed.size
}

extension Ed25519KeyPair: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> Ed25519KeyPair {
        let kp = try path.reduce(_keyPair) { (pair, cmp) in
            guard cmp.isHard else { throw KeyPairError.derive(error: .softDeriveIsNotSupported) }
            var encoder = ScaleCodec.encoder(reservedCapacity: 80)
            try encoder.encode("Ed25519HDKD")
            try encoder.encode(_keyPair.privateRaw, .fixed(UInt(EDKeyPair.secretSize)))
            try encoder.encode(cmp.bytes, .fixed(UInt(PathComponent.size)))
            let hash: Data = HBlake2b256.instance.hash(data: encoder.output)
            let seed = try Self.convertError { try EDSeed(raw: hash) }
            return EDKeyPair(seed: seed)
        }
        return Self(keyPair: kp)
    }
}

extension Substrate.Ed25519PublicKey: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> Substrate.Ed25519PublicKey {
        throw KeyPairError.derive(error: .softDeriveIsNotSupported)
    }
}

extension Substrate.Ed25519PublicKey {
    public func verify(signature: any Signature, message: Data) -> Bool {
        guard signature.algorithm == self.algorithm else {
            return false
        }
        guard let pub = try? EDPublicKey(raw: self.raw) else {
            return false
        }
        guard let sig = try? EDSignature(raw: signature.raw) else {
            return false
        }
        return pub.verify(message: message, signature: sig)
    }
}
