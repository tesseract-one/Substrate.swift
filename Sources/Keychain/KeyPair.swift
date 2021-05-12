//
//  KeyPair.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import Substrate

public protocol KeyPair {
    var typeId: CryptoTypeId { get }
    var rawPubKey: Data { get }
    
    init()
    init(phrase: String, password: String?) throws
    init(seed: Data) throws
    
    func pubKey(format: Ss58AddressFormat) -> PublicKey
    
    func sign(message: Data) throws -> Data
    func verify(message: Data, signature: Data) throws -> Bool
    
    static var seedLength: Int { get }
}


public enum KeyPairError: Error {
    public enum SecretParsingError: Error {
        case invalidFormat
        case invalidPath
        case invalidPhrase
        case invalidSeed
        case unknown(error: Error)
    }
    
    public enum PublicKeyParsingError: Error {
        case ss58(error: Ss58Error)
        case invalidFormat
        case invalidPath
        case unknown(error: Error)
    }
    
    case secretParsingError(error: SecretParsingError)
    case publicParsingError(error: PublicKeyParsingError)
    case signingFailed
    case badPublicKeyData
    case badSignatureData
    case badPrivateKeyData
    case badMessageData
    case wrongSeedSize
}

extension KeyPair where Self: Derivable {
    public static func parse(_ str: String, override password: String? = nil) throws -> Self {
        guard let match = SeedRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.count)) else {
            throw KeyPairError.secretParsingError(error: .invalidFormat)
        }
        let phrase = Range(match.range(at: 1), in: str).map{String(str[$0])} ?? DEFAULT_DEV_PHRASE
        let password = password != nil ? password : Range(match.range(at: 5), in: str).map{String(str[$0])}
        guard let path = Range(match.range(at: 2), in: str).map({String(str[$0])}) else {
            throw KeyPairError.secretParsingError(error: .invalidFormat)
        }
        let comps = PathRegex.matches(in: path, options: [], range: NSRange(location: 0, length: path.count))
        let derivations: [DeriveJunction] = try comps.map { match in
            guard let component = Range(match.range(at: 1), in: path).map({String(path[$0])}) else {
                throw KeyPairError.secretParsingError(error: .invalidPath)
            }
            do {
                return try DeriveJunction(path: component)
            } catch {
                throw KeyPairError.secretParsingError(error: .invalidPath)
            }
        }
        let root: Self
        if phrase.starts(with: "0x") {
            guard let seed = Hex.decode(hex: phrase) else {
                throw KeyPairError.secretParsingError(error: .invalidSeed)
            }
            do {
                root = try Self(seed: seed)
            } catch {
                throw KeyPairError.secretParsingError(error: .invalidSeed)
            }
        } else {
            do {
                root = try Self(phrase: phrase, password: password)
            } catch {
                throw KeyPairError.secretParsingError(error: .invalidPhrase)
            }
        }
        do {
            return try root.derive(path: derivations)
        } catch {
            throw KeyPairError.secretParsingError(error: .invalidPath)
        }
    }
}

private let SeedRegex = try! NSRegularExpression(pattern: #"^([\d\w ]+)?((//?[^/]+)*)(///(.*))?$"#, options: [])
private let PathRegex = try! NSRegularExpression(pattern: #"/(/?[^/]+)"#, options: [])
