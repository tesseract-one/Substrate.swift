//
//  Dispatch.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public enum DispatchError: ScaleCodable, ScaleDynamicCodable, Equatable {
    case other(String)
    case cannotLookup
    case badOrigin
    case module(index: UInt8, error: UInt8, message: String?)
    case consumerRemaining
    case noProviders
    case token(TokenError)
    case arithmetic(ArithmeticError)
    
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
        case 4: self = .consumerRemaining
        case 5: self = .noProviders
        case 6: self = try .token(decoder.decode())
        case 7: self = try .arithmetic(decoder.decode())
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
        case .consumerRemaining: try encoder.encode(4, .enumCaseId)
        case .noProviders: try encoder.encode(5, .enumCaseId)
        case .token(let err): try encoder.encode(6, .enumCaseId).encode(err)
        case .arithmetic(let err): try encoder.encode(7, .enumCaseId).encode(err)
        }
    }
}

extension DispatchError: Codable {
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "CannotLookup": self = .cannotLookup
            case "BadOrigin": self = .badOrigin
            case "ConsumerRemaining": self = .consumerRemaining
            case "NoProviders": self = .noProviders
            default:
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
            return
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            switch key {
            case .other:
                self = try .other(container2.decode(String.self, forKey: key))
            case .module:
                let m = try container2.decode(DispatchErrorModule.self, forKey: key)
                self = .module(index: m.index, error: m.error, message: m.message)
            case .token:
                self = try .token(container2.decode(TokenError.self, forKey: key))
            case .arithmetic:
                self = try .arithmetic(container2.decode(ArithmeticError.self, forKey: key))
            default:
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .cannotLookup:
            var container = encoder.singleValueContainer()
            try container.encode("CannotLookup")
        case .badOrigin:
            var container = encoder.singleValueContainer()
            try container.encode("BadOrigin")
        case .consumerRemaining:
            var container = encoder.singleValueContainer()
            try container.encode("ConsumerRemaining")
        case .noProviders:
            var container = encoder.singleValueContainer()
            try container.encode("NoProviders")
        case .other(let msg):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(msg, forKey: .other)
        case .module(index: let i, error: let e, message: let m):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(DispatchErrorModule(index: i, error: e, message: m), forKey: .module)
        case .token(let err):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(err, forKey: .token)
        case .arithmetic(let err):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(err, forKey: .arithmetic)
        }
    }
    
    private struct DispatchErrorModule: Codable {
        public let index: UInt8
        public let error: UInt8
        public let message: String?
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


private extension CodableComplexKey where T == DispatchError {
    static let other = Self(stringValue: "Other")!
    static let module = Self(stringValue: "Module")!
    static let token = Self(stringValue: "Token")!
    static let arithmetic = Self(stringValue: "Arithmetic")!
}
