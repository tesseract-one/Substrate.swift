//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import Foundation
import ScaleCodec

public enum StorageHasher: CaseIterable, ScaleDecodable {
    case blake2b128
    case blake2b256
    case blake2b128concat
    case xx128
    case xx256
    case xx64concat
    case identity
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
}

public struct StorageItemMetadata: ScaleDecodable {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryType
    public let defaultValue: Data
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        modifier = try decoder.decode()
        type = try decoder.decode()
        defaultValue = try decoder.decode()
        documentation = try decoder.decode()
    }
}

public struct StorageMetadata: ScaleDecodable {
    public let prefix: String
    public let items: [StorageItemMetadata]
    
    public init(from decoder: ScaleDecoder) throws {
        prefix = try decoder.decode()
        items = try decoder.decode()
    }
}
