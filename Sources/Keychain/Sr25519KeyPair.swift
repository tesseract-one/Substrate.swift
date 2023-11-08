//
//  Sr25519.swift
//  
//
//  Created by Yehor Popovych on 06.05.2021.
//

import Foundation
import Sr25519
import Bip39
import Substrate

public struct Sr25519KeyPair: Equatable, Hashable {
    private let _keyPair: Sr25519.Sr25519KeyPair
    public let publicKey: Substrate.Sr25519PublicKey
    
    private init(keyPair: Sr25519.Sr25519KeyPair) {
        self._keyPair = keyPair
        self.publicKey = try! Substrate.Sr25519PublicKey(keyPair.publicKey.raw)
    }
    
    fileprivate static func convertError<T>(_ cb: () throws -> T) throws -> T {
        do {
            return try cb()
        } catch let e as Sr25519Error {
            switch e {
            case .badChainCodeLength:
                throw KeyPairError.derive(error: .badComponentSize)
            case .badKeyPairLength:
                throw KeyPairError.native(error: .badPrivateKey)
            case .badPublicKeyLength:
                throw KeyPairError.input(error: .publicKey)
            case .badSeedLength:
                throw KeyPairError.input(error: .seed)
            case .badSignatureLength, .badVrfSignatureLength:
                throw KeyPairError.input(error: .signature)
            case .badVrfThresholdLength:
                throw KeyPairError.input(error: .threshold)
            case .vrfError:
                throw KeyPairError.native(error: .internal)
            }
        } catch {
            throw KeyPairError(error: error)
        }
    }
}

extension Sr25519KeyPair: KeyPair {
    public var algorithm: CryptoTypeId { .sr25519 }
    public var pubKey: any PublicKey { publicKey }
    public var raw: Data { _keyPair.raw }
    
    public init(seed: Data) throws {
        let kp = try Self.convertError {
            try Sr25519.Sr25519KeyPair(seed: Sr25519Seed(raw: seed.prefix(Sr25519Seed.size)))
        }
        self.init(keyPair: kp)
    }
    
    public init(raw: Data) throws {
        let kp = try Self.convertError {
            try Sr25519.Sr25519KeyPair(raw: raw)
        }
        self.init(keyPair: kp)
    }
    
    public init() {
        try! self.init(seed: Data(Random.bytes(count: Sr25519Seed.size)))
    }
    
    public func sign(message: Data) -> any Signature {
        try! Substrate.Sr25519Signature(raw: _keyPair.sign(message: message).raw)
    }
    
    public func verify(message: Data, signature: any Signature) -> Bool {
        guard signature.algorithm == self.algorithm else {
            return false
        }
        guard let sig = try? Sr25519.Sr25519Signature(raw: signature.raw) else {
            return false
        }
        return _keyPair.verify(message: message, signature: sig)
    }
    
    public func sign(tx: Data) -> any Signature {
        if tx.count > Ed25519KeyPair.nonHashedMaxSize {
            return sign(message: HBlake2b256.instance.hash(data: tx).raw)
        } else {
            return sign(message: tx)
        }
    }
    
    public func verify(tx: Data, signature: any Signature) -> Bool {
        if tx.count > Ed25519KeyPair.nonHashedMaxSize {
            return verify(message: HBlake2b256.instance.hash(data: tx).raw, signature: signature)
        } else {
            return verify(message: tx, signature: signature)
        }
    }
    
    public static var seedLength: Int = Sr25519Seed.size
}

extension Sr25519KeyPair: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> Sr25519KeyPair {
        let kp = try path.reduce(_keyPair) { (pair, cmp) in
            let chainCode = try Self.convertError { try Sr25519ChainCode(raw: cmp.bytes) }
            return pair.derive(chainCode: chainCode, hard: cmp.isHard)
        }
        return Self(keyPair: kp)
    }
}

extension Substrate.Sr25519PublicKey: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> Substrate.Sr25519PublicKey {
        let pub = try path.reduce(Sr25519.Sr25519PublicKey(raw: raw)) { (pub, cmp) in
            guard cmp.isSoft else { throw KeyPairError.derive(error: .publicDeriveHasHardPath) }
            let chainCode = try Sr25519KeyPair.convertError { try Sr25519ChainCode(raw: cmp.bytes) }
            return pub.derive(chainCode: chainCode)
        }
        do {
            return try Substrate.Sr25519PublicKey(pub.raw)
        } catch _ as SizeMismatchError {
            throw KeyPairError.input(error: .publicKey)
        }
    }
}

extension Substrate.Sr25519PublicKey {
    public func verify(signature: any Signature, message: Data) -> Bool {
        guard signature.algorithm == self.algorithm else {
            return false
        }
        guard let pub = try? Sr25519.Sr25519PublicKey(raw: self.raw) else {
            return false
        }
        guard let sig = try? Sr25519.Sr25519Signature(raw: signature.raw) else {
            return false
        }
        return pub.verify(message: message, signature: sig)
    }
    
    public func verify(signature: any Signature, tx: Data) -> Bool {
        if tx.count > Ed25519KeyPair.nonHashedMaxSize {
            return verify(signature: signature, message: HBlake2b256.instance.hash(data: tx).raw)
        } else {
            return verify(signature: signature, message: tx)
        }
    }
}
