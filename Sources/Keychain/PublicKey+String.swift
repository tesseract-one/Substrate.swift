//
//  PublicKey+String.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import Substrate

private let KeyRegex = try! NSRegularExpression(pattern: #"^([\w\d ]+)?((//?[^/]+)*)$"#, options: [])
private let PathRegex = try! NSRegularExpression(pattern: #"/(/?[^/]+)"#, options: [])

/// The root phrase for our publicly known keys.
public let DEFAULT_DEV_PHRASE = "bottom drive obey lake curtain smoke basket hold race lonely fit walk"

/// The address of the associated root phrase for our publicly known keys.
public let DEFAULT_DEV_ADDRESS = "5DfhGyQdFobKM8NsWvEeAKk5EQQgYe9AydgJ7rMB6E1EqRzV"

public enum PublicKeyParsingError: Error {
    case ss58(error: Ss58Error)
    case invalidFormat
    case invalidPath
    case unknown(error: Error)
}

#if !COCOAPODS
    public typealias PublicKey = SubstratePrimitives.PublicKey
#else
    public typealias PublicKey = Substrate.PublicKey
#endif

extension PublicKey where Self: Derivable {
    public static func from(string: String) throws -> Self {
        guard let match = KeyRegex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) else {
            throw PublicKeyParsingError.invalidFormat
        }
        let ss58: String = Range(match.range(at: 1), in: string).map {String(string[$0])} ?? DEFAULT_DEV_ADDRESS
        let path: String? = Range(match.range(at: 2), in: string).map {String(string[$0])}
        let parsed: Self
        do {
            parsed = try from(ss58: ss58)
        } catch let e as Ss58Error {
            throw PublicKeyParsingError.ss58(error: e)
        } catch {
            throw PublicKeyParsingError.unknown(error: error)
        }
        if let path = path {
            let matches = PathRegex.matches(in: path, options: [], range: NSRange(location: 0, length: path.count))
            let derives: [DeriveJunction] = try matches.map { match in
                guard let component = Range(match.range(at: 1), in: path).map({String(path[$0])}) else {
                    throw PublicKeyParsingError.invalidPath
                }
                do {
                    return try DeriveJunction(path: component)
                } catch {
                    throw PublicKeyParsingError.invalidPath
                }
            }
            do {
                return try parsed.derive(path: derives)
            } catch {
                throw PublicKeyParsingError.invalidPath
            }
        } else {
            return parsed
        }
    }
}
