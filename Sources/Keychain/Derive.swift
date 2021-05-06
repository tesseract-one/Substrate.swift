//
//  Derive.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import ScaleCodec
import Substrate

public enum DeriveJunction {
    /// Soft (vanilla) derivation. Public keys have a correspondent derivation.
    case soft(Data)
    /// Hard ("hardened") derivation. Public keys do not have a correspondent derivation.
    case hard(Data)
    
    /// The length of the junction identifier. Note that this is also referred to as the
    /// `CHAIN_CODE_LENGTH` in the context of Schnorrkel.
    public static let JUNCTION_ID_LEN = 32
    // Hasher for 32 byte length
    public static let hasher = HBlake2b256.hasher
}

extension DeriveJunction {
    /// return a soft derive junction with the same chain code.
    public var soften: Self { .soft(bytes) }

    /// return a hard derive junction with the same chain code.
    public var harden: Self { .hard(bytes) }

    /// Create a new soft (vanilla) DeriveJunction from a given, encodable, value.
    ///
    /// If you need a hard junction, use `init(hard: )`.
    public init<T: ScaleEncodable>(soft index: T) throws {
        let result: Data
        let data = try SCALE.default.encode(index)
        if data.count > Self.JUNCTION_ID_LEN {
            result = Self.hasher.hash(data: data)
        } else {
            result = data + Data(repeating: 0, count: Self.JUNCTION_ID_LEN - data.count)
        }
        self = .soft(result)
    }

    /// Create a new hard (hardened) DeriveJunction from a given, encodable, value.
    ///
    /// If you need a soft junction, use `init(soft: )`.
    public init<T: ScaleEncodable>(hard index: T) throws {
        self = try Self(soft: index).harden
    }
    
    public init(path: String) throws {
        let (code, hard) = path.starts(with: "/")
            ? (String(path.substr(from: 1)), true)
            : (path, false)
        let soft: Self
        if let uint = UInt64(code) {
            soft = try Self(soft: uint)
        } else {
            soft = try Self(soft: code)
        }
        self = hard ? soft.harden : soft
    }
    
    public var bytes: Data {
        switch self {
        case .soft(let data): return data
        case .hard(let data): return data
        }
    }

    /// Return `true` if the junction is soft.
    public var isSoft: Bool {
        switch self {
        case .soft: return true
        default: return false
        }
    }

    /// Return `true` if the junction is hard.
    public var isHard: Bool { !isSoft }
}

public enum DeriveError: Error {
    case publicHardPath
}

public protocol Derivable {
    func derive(path: [DeriveJunction]) throws -> Self
}
