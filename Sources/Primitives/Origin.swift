//
//  Origin.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec

public enum Origin<Id: ScaleDynamicCodable & Hashable> {
    case root
    case signed(Id)
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
    
    var signer: Id? {
        switch self {
        case .signed(let s): return s
        default: return nil
        }
    }
}

extension Origin: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = .root
        case 1: self = try .signed(Id(from: decoder, registry: registry))
        case 2: self = .none
        default: throw decoder.enumCaseError(for: opt)
        }
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        switch self {
        case .root: try encoder.encode(0, .enumCaseId)
        case .signed(let id): try id.encode(in: encoder.encode(1, .enumCaseId), registry: registry)
        case .none: try encoder.encode(2, .enumCaseId)
        }
    }
}
