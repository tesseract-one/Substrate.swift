//
//  EcdsaKeyPair.swift
//  
//
//  Created by Yehor Popovych on 12.05.2021.
//

import Foundation
import secp256k1
import Bip39

#if COCOAPODS
public typealias SBECPublicKey = Substrate.EcdsaPublicKey
public typealias SBECSignature = Substrate.EcdsaSignature
#else
import Substrate

public typealias SBECPublicKey = SubstratePrimitives.EcdsaPublicKey
public typealias SBECSignature = SubstratePrimitives.EcdsaSignature
#endif

public struct EcdsaKeyPair {
    private let _private: [UInt8]
    private let _public: secp256k1_pubkey
    private let _publicRaw: Data
    
    public func publicKey(format: Ss58AddressFormat) -> SBECPublicKey {
        try! SBECPublicKey(bytes: rawPubKey, format: format)
    }
    
    private init(privKey: [UInt8]) throws {
        guard Self._context.verify(privKey: privKey) else {
            throw KeyPairError.native(error: .badPrivateKey)
        }
        let pub = try Self._context.toPublicKey(privKey: privKey)
        let raw = try Data(Self._context.serialize(pubKey: pub, compressed: true))
        self._public = pub
        self._private = privKey
        self._publicRaw = raw
    }
    
    fileprivate static let _context = Secp256k1Context()
}

extension EcdsaKeyPair: KeyPair {
    public var rawPubKey: Data { _publicRaw }
    public var typeId: CryptoTypeId { .ecdsa }
    
    public init(phrase: String, password: String? = nil) throws {
        let mnemonic: Mnemonic
        do {
            mnemonic = try Mnemonic(mnemonic: phrase.components(separatedBy: " "))
        } catch {
            throw KeyPairError(error: error)
        }
        let seed = mnemonic.substrate_seed(password: password ?? "")
        try self.init(seed: Data(seed))
    }
    
    public init(seed: Data) throws {
        guard seed.count >= Secp256k1Context.privKeySize else {
            throw KeyPairError.input(error: .seed)
        }
        try self.init(privKey: Array(seed.prefix(Secp256k1Context.privKeySize)))
    }
    
    public init() {
        try! self.init(seed: Data(SubstrateKeychainRandom.bytes(count: Secp256k1Context.privKeySize)))
    }
    
    public func pubKey(format: Ss58AddressFormat) -> PublicKey {
        publicKey(format: format)
    }
    
    public func sign(message: Data) -> Data {
        let hash = HBlake2b256.hasher.hash(data: message)
        let signature = try! Self._context.sign(hash: Array(hash), privKey: self._private)
        return try! Data(Self._context.serialize(signature: signature))
    }
    
    public func verify(message: Data, signature: Data) -> Bool {
        guard let sig = try? Self._context.signature(from: Array(signature)) else {
            return false
        }
        let hash = HBlake2b256.hasher.hash(data: message)
        return Self._context.verify(signature: sig, hash: Array(hash), pubKey: self._public)
    }
    
    public static var seedLength: Int = Secp256k1Context.privKeySize
}

extension EcdsaKeyPair: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> EcdsaKeyPair {
        let priv = try path.reduce(_private) { (secret, cmp) in
            guard cmp.isHard else { throw KeyPairError.derive(error: .softDeriveIsNotSupported) }
            let encoder = SCALE.default.encoder()
            try encoder.encode("Secp256k1HDKD")
            try encoder.encode(Data(secret), .fixed(UInt(Secp256k1Context.privKeySize)))
            try encoder.encode(cmp.bytes, .fixed(UInt(PathComponent.size)))
            let hash = HBlake2b256.hasher.hash(data: encoder.output)
            return Array(hash.prefix(Secp256k1Context.privKeySize))
        }
        
        return try Self(privKey: priv)
    }
}

extension SBECPublicKey: KeyDerivable {
    public func derive(path: [PathComponent]) throws -> SBECPublicKey {
        throw KeyPairError.derive(error: .softDeriveIsNotSupported)
    }
}

extension SBECPublicKey {
    public func verify(signature: SBECSignature, message: Data) -> Bool {
        guard let sig = try? EcdsaKeyPair._context.signature(from: Array(signature.signature)) else {
            return false
        }
        guard let pub = try? EcdsaKeyPair._context.publicKey(from: Array(self.bytes)) else {
            return false
        }
        let hash =  HBlake2b256.hasher.hash(data: message)
        return EcdsaKeyPair._context.verify(signature: sig, hash: Array(hash), pubKey: pub)
    }
}
