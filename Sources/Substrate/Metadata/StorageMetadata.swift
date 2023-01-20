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
