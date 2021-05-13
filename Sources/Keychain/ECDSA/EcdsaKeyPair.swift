//
//  EcdsaKeyPair.swift
//  
//
//  Created by Yehor Popovych on 12.05.2021.
//

import Foundation
import Substrate
import secp256k1
import Bip39

#if COCOAPODS
public typealias SBECPublicKey = Substrate.EcdsaPublicKey
public typealias SBECSignature = Substrate.EcdsaSignature
#else
public typealias SBECPublicKey = SubstratePrimitives.EcdsaPublicKey
public typealias SBECSignature = SubstratePrimitives.EcdsaSignature
#endif

public struct EcdsaKeyPair: KeyPair {
    private let _private: [UInt8]
    private let _public: secp256k1_pubkey
    
    public let rawPubKey: Data
    public var typeId: CryptoTypeId { .ecdsa }
    
    public init(phrase: String, password: String? = nil) throws {
        let mnemonic: Mnemonic
        do {
            mnemonic = try Mnemonic(mnemonic: phrase.components(separatedBy: " "))
        } catch let e as Mnemonic.Error {
            throw KeyPairError.bip39(error: e)
        } catch {
            throw KeyPairError.unknown(error: error)
        }
        let seed = mnemonic.seed(password: password ?? "", wordlist: .english)
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
        try! SBECPublicKey(bytes: rawPubKey, format: format)
    }
    
    public func sign(message: Data) -> Data {
        let hash = HBlake2b256.hasher.hash(data: message)
        return try! context { secp in
            let signature = try secp.sign(hash: Array(hash), privKey: self._private)
            return try Data(secp.serialize(signature: signature))
        }
    }
    
    public func verify(message: Data, signature: Data) -> Bool {
        let res: Bool? = try? context { secp in
            let sig = try secp.signature(from: Array(signature))
            let hash = HBlake2b256.hasher.hash(data: message)
            return secp.verify(signature: sig, hash: Array(hash), pubKey: self._public)
        }
        return res ?? false
    }
    
    public static var seedLength: Int = Secp256k1Context.privKeySize
    
    private init(privKey: [UInt8]) throws {
        let (pub, raw) = try Self.context { secp -> (secp256k1_pubkey, Data) in
            guard secp.verify(privKey: privKey) else {
                throw KeyPairError.native(error: .badPrivateKey)
            }
            let pub = try secp.toPublicKey(privKey: privKey)
            let raw = try Data(secp.serialize(pubKey: pub, compressed: true))
            return (pub, raw)
        }
        self._public = pub
        self._private = privKey
        self.rawPubKey = raw
    }
}

extension EcdsaKeyPair {
    private static let _context = Secp256k1Context()
    private static let _contextQueue = DispatchQueue(
        label: "secp256k1_context_queue", target: .global(qos: .userInitiated)
    )
    
    static func context<T>(_ cb: (Secp256k1Context) throws -> T) rethrows -> T {
        try Self._contextQueue.sync { try cb(Self._context) }
    }
    
    func context<T>(_ cb: (Secp256k1Context) throws -> T) rethrows -> T {
        try Self.context(cb)
    }
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
        let hash =  HBlake2b256.hasher.hash(data: message)
        return EcdsaKeyPair.context { secp in
            guard let sig = try? secp.signature(from: Array(signature.signature)) else {
                return false
            }
            guard let pub = try? secp.publicKey(from: Array(self.bytes)) else {
                return false
            }
            return secp.verify(signature: sig, hash: Array(hash), pubKey: pub)
        }
    }
}
