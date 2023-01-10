//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec

public enum StorageHasher: CaseIterable, ScaleCodable, CustomStringConvertible {
    case blake2b128
    case blake2b256
    case blake2b128concat
    case xx128
    case xx256
    case xx64concat
    case identity
    
    public var hasher: Hasher {
        switch self {
        case .blake2b128: return HBlake2b128.hasher
        case .blake2b256: return HBlake2b256.hasher
        case .blake2b128concat: return HBlake2b128Concat.hasher
        case .xx128: return HXX128.hasher
        case .xx256: return HXX256.hasher
        case .xx64concat: return HXX64Concat.hasher
        case .identity: return HIdentity.hasher
        }
    }
    
    public var description: String {
        switch self {
        case .blake2b128: return "Blake2b128"
        case .blake2b256: return "Blake2b256"
        case .blake2b128concat: return "Blake2b128.Concat"
        case .xx128: return "TwoX128"
        case .xx256: return "TwoX256"
        case .xx64concat: return "TwoX64.Concat"
        case .identity: return "Identity"
        }
    }
}

public enum StorageEntryModifier: CaseIterable, ScaleCodable, CustomStringConvertible {
    case optional
    case `default`
    
    public var description: String {
        switch self {
        case .optional: return "Optional"
        case .default: return "Default"
        }
    }
}
//
//public enum StorageEntryType: ScaleDecodable, CustomStringConvertible {
//    case plain(String)
//    case map(
//        hasher: StorageHasher, key: String, value: String,
//        // is_linked flag previously, unused now to keep backwards compat
//        unused: Bool)
//    case doubleMap(
//        hasher: StorageHasher, key1: String,
//        key2: String, value: String,
//        key2_hasher: StorageHasher)
//
//    public init(from decoder: ScaleDecoder) throws {
//        let type = try decoder.decode(.enumCaseId)
//        switch type {
//        case 0:
//            self = try .plain(decoder.decode())
//        case 1:
//            self = try .map(
//                hasher: decoder.decode(), key: decoder.decode(),
//                value: decoder.decode(), unused: decoder.decode()
//            )
//        case 2:
//            self = try .doubleMap(
//                hasher: decoder.decode(), key1: decoder.decode(),
//                key2: decoder.decode(), value: decoder.decode(),
//                key2_hasher: decoder.decode()
//            )
//        default: throw decoder.enumCaseError(for: type)
//        }
//    }
//
//    public var path: [String] {
//        switch self {
//        case .plain(_): return []
//        case .map(hasher: _, key: let t, value: _, unused: _): return [t]
//        case .doubleMap(hasher: _, key1: let t1, key2: let t2, value: _, key2_hasher: _): return [t1, t2]
//        }
//    }
//
//    public var value: String {
//        switch self {
//        case .plain(let t): return t
//        case .map(hasher: _, key: _, value: let t, unused: _): return t
//        case .doubleMap(hasher: _, key1: _, key2: _, value: let t, key2_hasher: _): return t
//        }
//    }
//
//    public var description: String {
//        switch self {
//        case .plain(let t): return t
//        case .map(hasher: let h, key: let k, value: let v, unused: _): return "Map<\(h)(\(k)), \(v)>"
//        case .doubleMap(hasher: let h1, key1: let k1, key2: let k2, value: let v, key2_hasher: let h2):
//            return "Map<\(h1)(\(k1)), Map<\(h2)(\(k2)), \(v)>>"
//        }
//    }
//}
