//
//  Origin.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec

public enum Origin {
    case root
    case signed(AccountId)
    case none
    
    var isSigned: Bool {
        switch self {
        case .signed(_): return true
        default: return false
        }
    }
    
    var isNone: Bool {
        switch self {
        case .none: return true
        default: return false
        }
    }
    
    var isRoot: Bool {
        switch self {
        case .root: return true
        default: return false
        }
    }
    
    var signer: AccountId? {
        switch self {
        case .signed(let s): return s
        default: return nil
        }
    }
}

extension Origin: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = .root
        case 1: self = try .signed(decoder.decode())
        case 2: self = .none
        default: throw decoder.enumCaseError(for: opt)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .root: try encoder.encode(enumCaseId: 0)
        case .signed(let id): try encoder.encode(enumCaseId: 1).encode(id)
        case .none: try encoder.encode(enumCaseId: 2)
        }
    }
}

extension Origin: ScaleDynamicCodable {}
