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
