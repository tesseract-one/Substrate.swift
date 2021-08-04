//
//  Errors.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation
import ScaleCodec

public enum TokenError: UInt8, CaseIterable, ScaleCodable, ScaleDynamicCodable, Codable {
    case noFunds
    case wouldDie
    case belowMimimum
    case cannotCreate
    case unknownAsset
    case frozen
    case unsupported
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "NoFunds": self = .noFunds
        case "WouldDie": self = .wouldDie
        case "BelowMinimum": self = .belowMimimum
        case "CannotCreate": self = .cannotCreate
        case "UnknownAsset": self = .unknownAsset
        case "Frozen": self = .frozen
        case "Unsupported": self = .unsupported
        default:
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unknown enum value: \(value)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .noFunds: try container.encode("NoFunds")
        case .wouldDie: try container.encode("WouldDie")
        case .belowMimimum: try container.encode("BelowMinimum")
        case .cannotCreate: try container.encode("CannotCreate")
        case .unknownAsset: try container.encode("UnknownAsset")
        case .frozen: try container.encode("Frozen")
        case .unsupported: try container.encode("Unsupported")
        }
    }
}

public enum ArithmeticError: UInt8, CaseIterable, ScaleCodable, ScaleDynamicCodable, Codable {
    case underflow
    case overflow
    case divisionByZero
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "Underflow": self = .underflow
        case "Overflow": self = .overflow
        case "DivisionByZero": self = .divisionByZero
        default:
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unknown enum value: \(value)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .underflow: try container.encode("Underflow")
        case .overflow: try container.encode("Overflow")
        case .divisionByZero: try container.encode("DivisionByZero")
        }
    }
}
