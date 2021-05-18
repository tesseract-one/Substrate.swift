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

public struct Sr25519KeyPair {
    private let keyPair: SRKeyPair
    
    public func publicKey(format: Ss58AddressFormat) -> SBSRPublicKey {
        try! SBSRPublicKey(bytes: keyPair.publicKey.raw, format: format)
    }
    
    private init(keyPair: SRKeyPair) {
        self.keyPair = keyPair
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
    public var typeId: CryptoTypeId { .sr25519 }
    public var raw: Data { keyPair.raw }
    public var rawPubKey: Data { keyPair.publicKey.raw }
    
    public init(phrase: String, password: String? = nil) throws {
        let mnemonic = try Self.convertError {
            try Mnemonic(mnemonic: phrase.components(separatedBy: " "), wordlist: .english)
        }
        let seed = mnemonic.substrate_seed(password: password ?? "")
        try self.init(seed: Data(seed))
    }
    
    public init(seed: Data) throws {
        let kp = try Self.convertError {
            try SRKeyPair(seed: SRSeed(raw: seed.prefix(SRSeed.size)))
        }
        self.init(keyPair: kp)
    }
    
    public init(raw: Data) throws {
        let kp = try Self.convertError {
            try SRKeyPair(raw: raw)
        }
        self.init(keyPair: kp)
    }
    
    public init() {
        try! self.init(seed: Data(SubstrateKeychainRandom.bytes(count: SRSeed.size)))
    }
    
    public func pubKey(format: Ss58AddressFormat) -> PublicKey {
        publicKey(format: format)
    }
    
    public func sign(message: Data) -> Data {
        return keyPair.sign(message: message).raw
    }
    
    public func verify(message: Data, signature: Data) -> Bool {
        guard let sig = try? SRSignature(raw: signature) else {
            return false
        }
        return keyPair.verify(message: message, signature: sig)
    }
    
    public static var seedLength: Int = SRSeed.size
}

extension Sr25519KeyPair: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> Sr25519KeyPair {
        let kp = try path.reduce(keyPair) { (pair, cmp) in
            let chainCode = try Self.convertError { try SRChainCode(raw: cmp.bytes) }
            return pair.derive(chainCode: chainCode, hard: cmp.isHard)
        }
        return Self(keyPair: kp)
    }
}

extension SBSRPublicKey: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> SBSRPublicKey {
        let pub = try path.reduce(SRPublicKey(raw: bytes)) { (pub, cmp) in
            guard cmp.isSoft else { throw KeyPairError.derive(error: .publicDeriveHasHardPath) }
            let chainCode = try Sr25519KeyPair.convertError { try SRChainCode(raw: cmp.bytes) }
            return pub.derive(chainCode: chainCode)
        }
        do {
            return try SBSRPublicKey(bytes: pub.raw, format: format)
        } catch _ as SizeMismatchError {
            throw KeyPairError.input(error: .publicKey)
        }
        
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
