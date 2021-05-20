//
//  Secp256k1Context.swift
//  
//
//  Created by Yehor Popovych on 12.05.2021.
//

import Foundation
import CSecp256k1

class Secp256k1Context {
    var context: OpaquePointer!
    
    init() {
        let seed = SubstrateKeychainRandom.bytes(count: 32)
        context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))
        let _ = secp256k1_context_randomize(context, seed)
    }
    
    func verify(
        signature: secp256k1_ecdsa_recoverable_signature,
        hash: [UInt8], pubKey: secp256k1_pubkey
    ) -> Bool {
        guard hash.count == Self.messageSize else { return false }
        var signature = signature
        var pubKey = pubKey
        var ssig = secp256k1_ecdsa_signature()
        let res1 = secp256k1_ecdsa_recoverable_signature_convert(context, &ssig, &signature)
        guard res1 > 0 else { return false }
        return secp256k1_ecdsa_verify(context, &ssig, hash, &pubKey) == 1
    }
    
    func verify(privKey: [UInt8]) -> Bool {
        guard privKey.count == Self.privKeySize else { return false }
        return secp256k1_ec_seckey_verify(context, privKey) == 1
    }
    
    func sign(hash: [UInt8], privKey: [UInt8]) throws -> secp256k1_ecdsa_recoverable_signature {
        guard privKey.count == Self.privKeySize else { throw KeyPairError.native(error: .badPrivateKey) }
        guard hash.count == Self.messageSize else { throw KeyPairError.input(error: .message) }
        var signature = secp256k1_ecdsa_recoverable_signature()
        let res = secp256k1_ecdsa_sign_recoverable(context, &signature, hash, privKey, nil, nil)
        guard res > 0 else { throw KeyPairError.native(error: .internal) }
        return signature
    }
    
    func signature(from bytes: [UInt8]) throws -> secp256k1_ecdsa_recoverable_signature {
        guard bytes.count == Self.signatureSize else { throw KeyPairError.input(error: .signature) }
        var signature = secp256k1_ecdsa_recoverable_signature()
        let res = secp256k1_ecdsa_recoverable_signature_parse_compact(
            context, &signature, bytes,
            Int32(bytes[Self.signatureSize-1])
        )
        guard res > 0 else { throw KeyPairError.input(error: .signature) }
        return signature
    }
    
    func publicKey(from bytes: [UInt8]) throws -> secp256k1_pubkey {
        guard bytes.count == Self.compressedPubKeySize || bytes.count == Self.uncompressedPubKeySize else {
            throw KeyPairError.input(error: .publicKey)
        }
        var pubkey = secp256k1_pubkey()
        let res = secp256k1_ec_pubkey_parse(context, &pubkey, bytes, bytes.count)
        guard res > 0 else { throw KeyPairError.input(error: .publicKey) }
        return pubkey
    }
    
    func toPublicKey(privKey: [UInt8]) throws -> secp256k1_pubkey {
        guard privKey.count == Self.privKeySize else { throw KeyPairError.native(error: .badPrivateKey) }
        var pubkey = secp256k1_pubkey()
        let res = secp256k1_ec_pubkey_create(context, &pubkey, privKey)
        guard res > 0 else { throw KeyPairError.native(error: .internal) }
        return pubkey
    }
    
    func serialize(signature: secp256k1_ecdsa_recoverable_signature) throws -> [UInt8] {
        var sig = [UInt8](repeating: 0, count: Self.signatureSize)
        var signature = signature
        var recId: Int32 = 0
        secp256k1_ecdsa_recoverable_signature_serialize_compact(context, &sig, &recId, &signature)
        guard recId == 0 || recId == 1 else {
            throw KeyPairError.native(error: .internal)
        }
        sig[Self.signatureSize-1] = UInt8(recId)
        return sig
    }
    
    func serialize(pubKey: secp256k1_pubkey, compressed: Bool = true) throws -> [UInt8] {
        var keyLength = compressed ? Self.compressedPubKeySize : Self.uncompressedPubKeySize
        var serializedKey = [UInt8](repeating: 0, count: keyLength)
        var pub = pubKey
        let res = secp256k1_ec_pubkey_serialize(
            context, &serializedKey, &keyLength, &pub,
            UInt32(compressed ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED)
        )
        guard res > 0, keyLength == serializedKey.count else {
            throw KeyPairError.native(error: .internal)
        }
        return serializedKey
    }
    
    deinit {
        secp256k1_context_destroy(context)
        context = nil
    }
    
    static let privKeySize = 32
    static let messageSize = 32
    static let compressedPubKeySize = 33
    static let uncompressedPubKeySize = 65
    static let signatureSize = 65
}
