//
//  secp256k1.swift
//  
//
//  Created by Yehor Popovych on 12.05.2021.
//

import Foundation
import secp256k1

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
        guard hash.count == 32 else { return false }
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
        guard privKey.count == Self.privKeySize else { throw KeyPairError.badPrivateKeyData }
        guard hash.count == 32 else { throw KeyPairError.badMessageData }
        var signature = secp256k1_ecdsa_recoverable_signature()
        let res = secp256k1_ecdsa_sign_recoverable(context, &signature, hash, privKey, nil, nil)
        guard res > 0 else { throw KeyPairError.signingFailed }
        return signature
    }
    
    func signature(from bytes: [UInt8]) throws -> secp256k1_ecdsa_recoverable_signature {
        guard bytes.count == 65 else { throw KeyPairError.badSignatureData }
        var signature = secp256k1_ecdsa_recoverable_signature()
        let res = secp256k1_ecdsa_recoverable_signature_parse_compact(context, &signature, bytes, Int32(bytes[64]))
        guard res > 0 else { throw KeyPairError.badSignatureData }
        return signature
    }
    
    func publicKey(from bytes: [UInt8]) throws -> secp256k1_pubkey {
        guard bytes.count == 33 || bytes.count == 65 else {
            throw KeyPairError.badPublicKeyData
        }
        var pubkey = secp256k1_pubkey()
        let res = secp256k1_ec_pubkey_parse(context, &pubkey, bytes, bytes.count)
        guard res > 0 else { throw KeyPairError.badPublicKeyData }
        return pubkey
    }
    
    func toPublicKey(privKey: [UInt8]) throws -> secp256k1_pubkey {
        guard privKey.count == Self.privKeySize else { throw KeyPairError.badPrivateKeyData }
        var pubkey = secp256k1_pubkey()
        let res = secp256k1_ec_pubkey_create(context, &pubkey, privKey)
        guard res > 0 else { throw KeyPairError.badPrivateKeyData }
        return pubkey
    }
    
    func serialize(signature: secp256k1_ecdsa_recoverable_signature) throws -> [UInt8] {
        var sig = [UInt8](repeating: 0, count: 65)
        var signature = signature
        var recId: Int32 = 0
        secp256k1_ecdsa_recoverable_signature_serialize_compact(context, &sig, &recId, &signature)
        guard recId == 0 || recId == 1 else {
            throw KeyPairError.badSignatureData
        }
        sig[64] = UInt8(recId)
        return sig
    }
    
    func serialize(pubKey: secp256k1_pubkey, compressed: Bool = true) throws -> [UInt8] {
        var keyLength = compressed ? 33 : 65
        var serializedKey = [UInt8](repeating: 0, count: keyLength)
        var pub = pubKey
        let res = secp256k1_ec_pubkey_serialize(
            context, &serializedKey, &keyLength, &pub,
            UInt32(compressed ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED)
        )
        guard res > 0, keyLength == serializedKey.count else {
            throw KeyPairError.badPublicKeyData
        }
        return serializedKey
    }
    
    deinit {
        secp256k1_context_destroy(context)
        context = nil
    }
    
    static let privKeySize = 32
}
