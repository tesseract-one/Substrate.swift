//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec

public protocol RuntimeMetadata {
    var version: UInt8 { get }
    var modules: [RuntimeModuleMetadata] { get }
    var extrinsic: RuntimeExtrinsicMetadata { get }
}

public protocol RuntimeExtrinsicMetadata {
    var version: UInt8 { get }
    var signedExtensions: [String] { get }
}

public protocol RuntimeModuleMetadata {
    var index: UInt8 { get }
    var name: String { get }
    var storage: Optional<RuntimeStorageMetadata> { get }
    var calls: Optional<[RuntimeCallMetadata]> { get }
    var events: Optional<[RuntimeEventMetadata]> { get }
    var constants: [RuntimeConstantMetadata] { get }
    var errors: [RuntimeErrorMetadata] { get }
}

public enum StorageHasher: CaseIterable, ScaleDecodable {
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
}

public enum StorageEntryModifier: CaseIterable, ScaleDecodable {
    case optional
    case `default`
}

public enum StorageEntryType: ScaleDecodable {
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
}

public protocol RuntimeStorageItemMetadata {
    var name: String { get }
    var modifier: StorageEntryModifier { get }
    var type: StorageEntryType { get }
    var defaultValue: Data { get }
    var documentation: [String] { get }
}

public protocol RuntimeStorageMetadata {
    var prefix: String { get }
    var items: [RuntimeStorageItemMetadata] { get }
}

public protocol RuntimeCallArgumentsMetadata {
    var name: String { get }
    var type: String { get }
}

public protocol RuntimeCallMetadata {
    var name: String { get }
    var arguments: [RuntimeCallArgumentsMetadata] { get }
    var documentation: [String] { get }
}

public protocol RuntimeEventMetadata {
    var name: String { get }
    var arguments: [String] { get }
    var documentation: [String] { get }
}

public protocol RuntimeConstantMetadata {
    var name: String { get }
    var type: String { get }
    var value: Data { get }
    var documentation: [String] { get }
}

public protocol RuntimeErrorMetadata {
    var name: String { get }
    var documentation: [String] { get }
}
