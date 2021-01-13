//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public enum Address<Id: ScaleCodable & Hashable, Index: ScaleCodable & Hashable>: Equatable, Hashable {
    case id(Id)
    case index(Index)
    
    public var isId: Bool {
        guard case .id(_) = self else {
            return false
        }
        return true
    }
    
    public init(id: Id) {
        self = .id(id)
    }
    
    public init(index: Index) {
        self = .index(index)
    }
}

extension Address: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let type = try decoder.peek(count: 1).first!
        if type == 0xff {
            let _ = try decoder.read(count: 1)
            self = try .id(decoder.decode())
        } else {
            self = try .index(decoder.decode())
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .id(let id): try encoder.encode(UInt8(0xff)).encode(id)
        case .index(let index): try encoder.encode(index)
        }
    }
}

extension Address: ScaleDynamicCodable {}
