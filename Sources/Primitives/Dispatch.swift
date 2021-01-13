//
//  Dispatch.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public enum DispatchError: ScaleCodable, ScaleDynamicCodable {
    case other(String)
    case cannotLookup
    case badOrigin
    case module(index: UInt8, error: UInt8, message: String?)
    
    public init(from decoder: ScaleDecoder) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = try .other(decoder.decode())
        case 1: self = .cannotLookup
        case 2: self = .badOrigin
        case 3: self = try .module(
                index: decoder.decode(),
                error: decoder.decode(),
                message: decoder.decode()
            )
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .other(let s): try encoder.encode(0, .enumCaseId).encode(s)
        case .cannotLookup: try encoder.encode(1, .enumCaseId)
        case .badOrigin: try encoder.encode(2, .enumCaseId)
        case .module(index: let i, error: let e, message: let m):
            try encoder.encode(3, .enumCaseId).encode(i).encode(e).encode(m)
        }
    }
}


public struct DispatchInfo: ScaleCodable, ScaleDynamicCodable {
    public enum Class: CaseIterable, ScaleCodable, ScaleDynamicCodable {
        case normal
        case operational
        case mandatory
    }
    
    public enum Pays: CaseIterable, ScaleCodable, ScaleDynamicCodable {
        case yes
        case no
    }
    
    public let weight: UInt64
    public let clazz: Class
    public let paysFee: Pays
    
    public init(from decoder: ScaleDecoder) throws {
        weight = try decoder.decode()
        clazz = try decoder.decode()
        paysFee = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(weight).encode(clazz).encode(paysFee)
    }
}
