//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec

public enum StorageHasher: CaseIterable, ScaleCodec.Codable, CustomStringConvertible {
    case blake2b128
    case blake2b256
    case blake2b128concat
    case xx128
    case xx256
    case xx64concat
    case identity
    
    public var hasher: Hasher {
        switch self {
        case .blake2b128: return HBlake2b128.instance
        case .blake2b256: return HBlake2b256.instance
        case .blake2b128concat: return HBlake2b128Concat.instance
        case .xx128: return HXX128.instance
        case .xx256: return HXX256.instance
        case .xx64concat: return HXX64Concat.instance
        case .identity: return HIdentity.instance
        }
    }
    
    public var description: String {
        switch self {
        case .blake2b128: return "Blake2_128"
        case .blake2b256: return "Blake2_256"
        case .blake2b128concat: return "Blake2_128Concat"
        case .xx128: return "Twox128"
        case .xx256: return "Twox256"
        case .xx64concat: return "Twox64Concat"
        case .identity: return "Identity"
        }
    }
}

public enum StorageEntryModifier: CaseIterable, ScaleCodec.Codable, CustomStringConvertible {
    case optional
    case `default`
    
    public var description: String {
        switch self {
        case .optional: return "Optional"
        case .default: return "Default"
        }
    }
}
