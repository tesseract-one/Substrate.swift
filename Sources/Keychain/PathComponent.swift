//
//  PathComponent.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import ScaleCodec
#if !COCOAPODS
import Substrate
#endif

public enum PathComponent {
    /// Soft (vanilla) derivation. Public keys have a correspondent derivation.
    case soft(Data)
    /// Hard ("hardened") derivation. Public keys do not have a correspondent derivation.
    case hard(Data)
    
    /// The length of the path identifier. Note that this is also referred to as the
    /// `CHAIN_CODE_LENGTH` in the context of Schnorrkel.
    public static let size = 32
    // Hasher for 32 byte length
    public static let hasher = HBlake2b256.instance
}

extension PathComponent {
    /// return a soft path component with the same chain code.
    public var soften: Self { .soft(bytes) }

    /// return a hard path component with the same chain code.
    public var harden: Self { .hard(bytes) }

    /// Create a new soft (vanilla) PathComponent from a given, encodable, value.
    ///
    /// If you need a hard component, use `init(hard: )`.
    public init<T: ScaleCodec.Encodable>(soft index: T) throws {
        var result: Data
        switch index {
        case let arr as [UInt8]: result = Data(arr)
        case let data as Data: result = data
        default: result = try ScaleCodec.encode(index, reservedCapacity: 256) // Should be enough for strings
        }
        if result.count > Self.size {
            result = Self.hasher.hash(data: result)
        } else {
            result = result + Data(repeating: 0, count: Self.size - result.count)
        }
        self = .soft(result)
    }

    /// Create a new hard (hardened) PathComponent from a given, encodable, value.
    ///
    /// If you need a hard component, use `init(soft: )`.
    public init<T: ScaleCodec.Encodable>(hard index: T) throws {
        self = try Self(soft: index).harden
    }
    
    /// Parses string path component.
    public init(string component: String) throws {
        let (code, hard) = component.starts(with: "/")
            ? (String(component[component.index(after: component.startIndex)...]), true)
            : (component, false)
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
