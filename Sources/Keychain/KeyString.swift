//
//  KeyString.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation
#if !COCOAPODS
import Substrate
#endif

/// The root phrase for our publicly known keys.
public var DEFAULT_DEV_PHRASE = "bottom drive obey lake curtain smoke basket hold race lonely fit walk"

/// The address of the associated root phrase for our publicly known keys.
public var DEFAULT_DEV_ADDRESS = "5DfhGyQdFobKM8NsWvEeAKk5EQQgYe9AydgJ7rMB6E1EqRzV"

public protocol KeyDerivable {
    func derive(path: [PathComponent]) throws -> Self
}

extension PublicKey where Self: KeyDerivable {
    public init(parsing string: String) throws {
        guard let match = KeyRegex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) else {
            throw KeyPairError.publicParsing(error: .invalidFormat)
        }
        let ss58: String = Range(match.range(at: 1), in: string).map {String(string[$0])} ?? DEFAULT_DEV_ADDRESS
        let path: String? = Range(match.range(at: 2), in: string).map {String(string[$0])}
        var parsed: Self
        do {
            parsed = try Self(ss58: ss58)
        } catch let e as SS58.Error {
            throw KeyPairError.publicParsing(error: .ss58(error: e))
        } catch {
            throw KeyPairError.publicParsing(error: .unknown(error: error))
        }
        if let path = path {
            let matches = PathRegex.matches(in: path, options: [], range: NSRange(location: 0, length: path.count))
            let derives: [PathComponent] = try matches.map { match in
                guard let component = Range(match.range(at: 1), in: path).map({String(path[$0])}) else {
                    throw KeyPairError.publicParsing(error: .invalidPath)
                }
                do {
                    return try PathComponent(string: component)
                } catch {
                    throw KeyPairError.publicParsing(error: .invalidPath)
                }
            }
            do {
                parsed = try parsed.derive(path: derives)
            } catch {
                throw KeyPairError.publicParsing(error: .invalidPath)
            }
        }
        try self.init(parsed.raw)
    }
}

extension KeyPair where Self: KeyDerivable {
    public init(parsing str: String, override password: String? = nil) throws {
        guard let match = SeedRegex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.count)) else {
            throw KeyPairError.secretParsing(error: .invalidFormat)
        }
        let phrase = Range(match.range(at: 1), in: str).map{String(str[$0])} ?? DEFAULT_DEV_PHRASE
        let password = password != nil ? password : Range(match.range(at: 5), in: str).map{String(str[$0])}
        guard let path = Range(match.range(at: 2), in: str).map({String(str[$0])}) else {
            throw KeyPairError.secretParsing(error: .invalidFormat)
        }
        let comps = PathRegex.matches(in: path, options: [], range: NSRange(location: 0, length: path.count))
        let derivations: [PathComponent] = try comps.map { match in
            guard let component = Range(match.range(at: 1), in: path).map({String(path[$0])}) else {
                throw KeyPairError.secretParsing(error: .invalidPath)
            }
            do {
                return try PathComponent(string: component)
            } catch {
                throw KeyPairError.secretParsing(error: .invalidPath)
            }
        }
        var root: Self
        if phrase.starts(with: "0x") {
            guard let seed = Data(hex: phrase) else {
                throw KeyPairError.secretParsing(error: .invalidSeed)
            }
            do {
                root = try Self(seed: seed)
            } catch {
                throw KeyPairError.secretParsing(error: .invalidSeed)
            }
        } else {
            do {
                root = try Self(phrase: phrase, password: password)
            } catch {
                throw KeyPairError.secretParsing(error: .invalidPhrase)
            }
        }
        do {
            root = try root.derive(path: derivations)
        } catch {
            throw KeyPairError.secretParsing(error: .invalidPath)
        }
        try self.init(raw: root.raw)
    }
}

private let SeedRegex = try! NSRegularExpression(pattern: #"^([\d\w ]+)?((//?[^/]+)*)(///(.*))?$"#, options: [])
private let KeyRegex = try! NSRegularExpression(pattern: #"^([\w\d ]+)?((//?[^/]+)*)$"#, options: [])
private let PathRegex = try! NSRegularExpression(pattern: #"/(/?[^/]+)"#, options: [])
