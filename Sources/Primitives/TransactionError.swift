//
//  TransactionError.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation
import ScaleCodec

public enum TransactionValidityError: Equatable, Codable, ScaleCodable, ScaleDynamicCodable {
    case invalid(InvalidTransaction)
    case unknown(UnknownTransaction)
    
    public init(from decoder: ScaleDecoder) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = try .invalid(decoder.decode())
        case 1: self = try .unknown(decoder.decode())
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .invalid(let e): try encoder.encode(0, .enumCaseId).encode(e)
        case .unknown(let e): try encoder.encode(1, .enumCaseId).encode(e)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
        guard let key = container2.allKeys.first else {
            throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
        }
        switch key {
        case .invalid:
            self = try .invalid(container2.decode(InvalidTransaction.self, forKey: key))
        case .unknown:
            self = try .unknown(container2.decode(UnknownTransaction.self, forKey: key))
        default:
            throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .invalid(let e):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(e, forKey: .invalid)
        case .unknown(let e):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(e, forKey: .unknown)
        }
    }
}

public enum InvalidTransaction: Equatable, Codable, ScaleCodable, ScaleDynamicCodable {
    case call
    case payment
    case future
    case stale
    case badProof
    case ancientBirthBlock
    case exhaustsResources
    case custom(UInt8)
    case badMandatory
    case mandatoryDispatch
    
    public init(from decoder: ScaleDecoder) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = .call
        case 1: self = .payment
        case 2: self = .future
        case 3: self = .stale
        case 4: self = .badProof
        case 5: self = .ancientBirthBlock
        case 6: self = .exhaustsResources
        case 7: self = try .custom(decoder.decode())
        case 8: self = .badMandatory
        case 9: self = .mandatoryDispatch
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .call: try encoder.encode(0, .enumCaseId)
        case .payment: try encoder.encode(1, .enumCaseId)
        case .future: try encoder.encode(2, .enumCaseId)
        case .stale: try encoder.encode(3, .enumCaseId)
        case .badProof: try encoder.encode(4, .enumCaseId)
        case .ancientBirthBlock: try encoder.encode(5, .enumCaseId)
        case .exhaustsResources: try encoder.encode(6, .enumCaseId)
        case .custom(let e): try encoder.encode(7, .enumCaseId).encode(e)
        case .badMandatory: try encoder.encode(8, .enumCaseId)
        case .mandatoryDispatch: try encoder.encode(9, .enumCaseId)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "Call": self = .call
            case "Payment": self = .payment
            case "Future": self = .future
            case "Stale": self = .stale
            case "BadProof": self = .badProof
            case "AncientBirthBlock": self = .ancientBirthBlock
            case "ExhaustsResources": self = .exhaustsResources
            case "BadMandatory": self = .badMandatory
            case "MandatoryDispatch": self = .mandatoryDispatch
            default:
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
            return
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            guard key == .custom else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
            self = try .custom(container2.decode(UInt8.self, forKey: key))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .call:
            var container = encoder.singleValueContainer()
            try container.encode("Call")
        case .payment:
            var container = encoder.singleValueContainer()
            try container.encode("Payment")
        case .future:
            var container = encoder.singleValueContainer()
            try container.encode("Future")
        case .stale:
            var container = encoder.singleValueContainer()
            try container.encode("Stale")
        case .badProof:
            var container = encoder.singleValueContainer()
            try container.encode("BadProof")
        case .ancientBirthBlock:
            var container = encoder.singleValueContainer()
            try container.encode("AncientBirthBlock")
        case .exhaustsResources:
            var container = encoder.singleValueContainer()
            try container.encode("ExhaustsResources")
        case .badMandatory:
            var container = encoder.singleValueContainer()
            try container.encode("BadMandatory")
        case .mandatoryDispatch:
            var container = encoder.singleValueContainer()
            try container.encode("MandatoryDispatch")
        case .custom(let id):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(id, forKey: .custom)
        }
    }
}

public enum UnknownTransaction: Equatable, Codable, ScaleCodable, ScaleDynamicCodable {
    case cannotLookup
    case noUnsignedValidator
    case custom(UInt8)
    
    public init(from decoder: ScaleDecoder) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = .cannotLookup
        case 1: self = .noUnsignedValidator
        case 2: self = try .custom(decoder.decode())
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .cannotLookup: try encoder.encode(0, .enumCaseId)
        case .noUnsignedValidator: try encoder.encode(1, .enumCaseId)
        case .custom(let e): try encoder.encode(2, .enumCaseId).encode(e)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "CannotLookup": self = .cannotLookup
            case "NoUnsignedValidator": self = .noUnsignedValidator
            default:
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
            return
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            guard key == .custom else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
            self = try .custom(container2.decode(UInt8.self, forKey: key))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .cannotLookup:
            var container = encoder.singleValueContainer()
            try container.encode("CannotLookup")
        case .noUnsignedValidator:
            var container = encoder.singleValueContainer()
            try container.encode("NoUnsignedValidator")
        case .custom(let id):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(id, forKey: .custom)
        }
    }
}

private extension CodableComplexKey where T == UnknownTransaction {
    static let custom = Self(stringValue: "Custom")!
}

private extension CodableComplexKey where T == InvalidTransaction {
    static let custom = Self(stringValue: "Custom")!
}

private extension CodableComplexKey where T == TransactionValidityError {
    static let invalid = Self(stringValue: "Invalid")!
    static let unknown = Self(stringValue: "Unknown")!
}
