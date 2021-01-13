//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec

public protocol RuntimeMetadata: Encodable {
    var version: UInt8 { get }
    var modules: [RuntimeModuleMetadata] { get }
    var extrinsic: RuntimeExtrinsicMetadata { get }
}

public protocol RuntimeExtrinsicMetadata: Encodable {
    var version: UInt8 { get }
    var signedExtensions: [String] { get }
}

public protocol RuntimeModuleMetadata: Encodable {
    var index: UInt8 { get }
    var name: String { get }
    var storage: Optional<RuntimeStorageMetadata> { get }
    var calls: Optional<[RuntimeCallMetadata]> { get }
    var events: Optional<[RuntimeEventMetadata]> { get }
    var constants: [RuntimeConstantMetadata] { get }
    var errors: [RuntimeErrorMetadata] { get }
}

public enum StorageHasher: CaseIterable, ScaleDecodable, Encodable, CustomStringConvertible {
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public enum StorageEntryModifier: CaseIterable, ScaleDecodable, Encodable, CustomStringConvertible {
    case optional
    case `default`
    
    public var description: String {
        switch self {
        case .optional: return "Optional"
        case .default: return "Default"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public enum StorageEntryType: ScaleDecodable, Encodable, CustomStringConvertible {
    case plain(String)
    case map(
        hasher: StorageHasher, key: String, value: String,
        // is_linked flag previously, unused now to keep backwards compat
        unused: Bool)
    case doubleMap(
        hasher: StorageHasher, key1: String,
        key2: String, value: String,
        key2_hasher: StorageHasher)
    
    public init(from decoder: ScaleDecoder) throws {
        let type = try decoder.decode(.enumCaseId)
        switch type {
        case 0:
            self = try .plain(decoder.decode())
        case 1:
            self = try .map(
                hasher: decoder.decode(), key: decoder.decode(),
                value: decoder.decode(), unused: decoder.decode()
            )
        case 2:
            self = try .doubleMap(
                hasher: decoder.decode(), key1: decoder.decode(),
                key2: decoder.decode(), value: decoder.decode(),
                key2_hasher: decoder.decode()
            )
        default: throw decoder.enumCaseError(for: type)
        }
    }
    
    public var path: [String] {
        switch self {
        case .plain(_): return []
        case .map(hasher: _, key: let t, value: _, unused: _): return [t]
        case .doubleMap(hasher: _, key1: let t1, key2: let t2, value: _, key2_hasher: _): return [t1, t2]
        }
    }
    
    public var value: String {
        switch self {
        case .plain(let t): return t
        case .map(hasher: _, key: _, value: let t, unused: _): return t
        case .doubleMap(hasher: _, key1: _, key2: _, value: let t, key2_hasher: _): return t
        }
    }
    
    public var description: String {
        switch self {
        case .plain(let t): return t
        case .map(hasher: let h, key: let k, value: let v, unused: _): return "Map<\(h)(\(k)), \(v)>"
        case .doubleMap(hasher: let h1, key1: let k1, key2: let k2, value: let v, key2_hasher: let h2):
            return "Map<\(h1)(\(k1)), Map<\(h2)(\(k2)), \(v)>>"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public protocol RuntimeStorageItemMetadata: Encodable {
    var name: String { get }
    var modifier: StorageEntryModifier { get }
    var type: StorageEntryType { get }
    var defaultValue: Data { get }
    var documentation: [String] { get }
}

public protocol RuntimeStorageMetadata: Encodable {
    var prefix: String { get }
    var items: [RuntimeStorageItemMetadata] { get }
}

public protocol RuntimeCallArgumentsMetadata: Encodable {
    var name: String { get }
    var type: String { get }
}

public protocol RuntimeCallMetadata: Encodable {
    var name: String { get }
    var arguments: [RuntimeCallArgumentsMetadata] { get }
    var documentation: [String] { get }
}

public protocol RuntimeEventMetadata: Encodable {
    var name: String { get }
    var arguments: [String] { get }
    var documentation: [String] { get }
}

public protocol RuntimeConstantMetadata: Encodable {
    var name: String { get }
    var type: String { get }
    var value: Data { get }
    var documentation: [String] { get }
}

public protocol RuntimeErrorMetadata: Encodable {
    var name: String { get }
    var documentation: [String] { get }
}
