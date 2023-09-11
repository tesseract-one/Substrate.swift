//
//  TransactionValidityError.swift
//  
//
//  Created by Yehor Popovych on 24/08/2023.
//

import Foundation
import ScaleCodec

/// Errors that can occur while checking the validity of a transaction.
public enum TransactionValidityError: StaticCallError, Equatable, Swift.Codable,
                                      RuntimeSwiftCodable, ScaleCodec.Codable, RuntimeCodable
{
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
    
    /// The transaction is invalid.
    case invalid(InvalidTransaction)
    /// Transaction validity can't be determined.
    case unknown(UnknownTransaction)
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = try .invalid(decoder.decode())
        case 1: self = try .unknown(decoder.decode())
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        switch self {
        case .invalid(let e):
            try encoder.encode(0, .enumCaseId)
            try encoder.encode(e)
        case .unknown(let e):
            try encoder.encode(1, .enumCaseId)
            try encoder.encode(e)
        }
    }
    
    public init(from decoder: Swift.Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
        guard let key = container2.allKeys.first else {
            throw Swift.DecodingError.dataCorruptedError(
                in: container1, debugDescription: "Empty case object"
            )
        }
        switch key {
        case .invalid:
            self = try .invalid(container2.decode(InvalidTransaction.self, forKey: key))
        case .unknown:
            self = try .unknown(container2.decode(UnknownTransaction.self, forKey: key))
        default:
            throw Swift.DecodingError.dataCorruptedError(
                forKey: key, in: container2, debugDescription: "Unknown enum case"
            )
        }
    }
    
    public func encode(to encoder: Swift.Encoder) throws {
        switch self {
        case .invalid(let e):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(e, forKey: .invalid)
        case .unknown(let e):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(e, forKey: .unknown)
        }
    }
    
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .variant(variants: [
            .s(0, "Invalid", registry.def(InvalidTransaction.self)),
            .s(1, "Unknown", registry.def(UnknownTransaction.self))
        ])
    }
}

public extension TransactionValidityError {
    /// An invalid transaction validity.
    enum InvalidTransaction: Error, Equatable, Swift.Codable, ScaleCodec.Codable,
                             RuntimeCodable, RuntimeSwiftCodable, IdentifiableType
    {
        public typealias DecodingContext = VoidCodableContext
        public typealias EncodingContext = VoidCodableContext
        
        /// The call of the transaction is not expected.
        case call
        /// General error to do with the inability to pay some fees (e.g. account balance too low).
        case payment
        /// General error to do with the transaction not yet being valid (e.g. nonce too high).
        case future
        /// General error to do with the transaction being outdated (e.g. nonce too low).
        case stale
        /// General error to do with the transaction's proofs (e.g. signature).
        ///
        /// # Possible causes
        ///
        /// When using a signed extension that provides additional data for signing, it is required
        /// that the signing and the verifying side use the same additional data. Additional
        /// data will only be used to generate the signature, but will not be part of the transaction
        /// itself. As the verifying side does not know which additional data was used while signing
        /// it will only be able to assume a bad signature and cannot express a more meaningful error.
        case badProof
        /// The transaction birth block is ancient.
        ///
        /// # Possible causes
        ///
        /// For `FRAME`-based runtimes this would be caused by `current block number
        /// - Era::birth block number > BlockHashCount`. (e.g. in Polkadot `BlockHashCount` = 2400, so
        ///   a
        /// transaction with birth block number 1337 would be valid up until block number 1337 + 2400,
        /// after which point the transaction would be considered to have an ancient birth block.)
        case ancientBirthBlock
        /// The transaction would exhaust the resources of current block.
        ///
        /// The transaction might be valid, but there are not enough resources
        /// left in the current block.
        case exhaustsResources
        /// Any other custom invalid validity that is not covered by this enum.
        case custom(UInt8)
        /// An extrinsic with a Mandatory dispatch resulted in Error. This is indicative of either a
        /// malicious validator or a buggy `provide_inherent`. In any case, it can result in
        /// dangerously overweight blocks and therefore if found, invalidates the block.
        case badMandatory
        /// An extrinsic with a mandatory dispatch tried to be validated.
        /// This is invalid; only inherent extrinsics are allowed to have mandatory dispatches.
        case mandatoryValidation
        /// The sending address is disabled or known to be invalid.
        case badSigner
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
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
            case 9: self = .mandatoryValidation
            case 10: self = .badSigner
            default: throw decoder.enumCaseError(for: id)
            }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            switch self {
            case .call: try encoder.encode(0, .enumCaseId)
            case .payment: try encoder.encode(1, .enumCaseId)
            case .future: try encoder.encode(2, .enumCaseId)
            case .stale: try encoder.encode(3, .enumCaseId)
            case .badProof: try encoder.encode(4, .enumCaseId)
            case .ancientBirthBlock: try encoder.encode(5, .enumCaseId)
            case .exhaustsResources: try encoder.encode(6, .enumCaseId)
            case .custom(let e):
                try encoder.encode(7, .enumCaseId)
                try encoder.encode(e)
            case .badMandatory: try encoder.encode(8, .enumCaseId)
            case .mandatoryValidation: try encoder.encode(9, .enumCaseId)
            case .badSigner: try encoder.encode(10, .enumCaseId)
            }
        }
        
        public init(from decoder: Swift.Decoder) throws {
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
                case "MandatoryValidation": self = .mandatoryValidation
                case "BadSigner": self = .badSigner
                default:
                    throw Swift.DecodingError.dataCorruptedError(
                        in: container1, debugDescription: "Unknown case \(simple)"
                    )
                }
                return
            } else {
                let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
                guard let key = container2.allKeys.first else {
                    throw Swift.DecodingError.dataCorruptedError(
                        in: container1, debugDescription: "Empty case object"
                    )
                }
                guard key == .custom else {
                    throw Swift.DecodingError.dataCorruptedError(
                        forKey: key, in: container2, debugDescription: "Unknow enum case"
                    )
                }
                self = try .custom(container2.decode(UInt8.self, forKey: key))
            }
        }
        
        public func encode(to encoder: Swift.Encoder) throws {
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
            case .mandatoryValidation:
                var container = encoder.singleValueContainer()
                try container.encode("MandatoryValidation")
            case .badSigner:
                var container = encoder.singleValueContainer()
                try container.encode("BadSigner")
            case .custom(let id):
                var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
                try container.encode(id, forKey: .custom)
            }
        }
        
        @inlinable
        public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .variant(variants: [
                .e(0, "Call"), .e(1, "Payment"), .e(2, "Future"), .e(3, "Stale"),
                .e(4, "BadProof"), .e(5, "AncientBirthBlock"), .e(6, "ExhaustsResources"),
                .s(7, "Custom", registry.def(UInt8.self)), .e(8, "BadMandatory"),
                .e(9, "MandatoryValidation"), .e(10, "BadSigner")
            ])
        }
    }
}

public extension TransactionValidityError {
    /// An unknown transaction validity.
    enum UnknownTransaction: Error, Equatable, Swift.Codable, ScaleCodec.Codable,
                             RuntimeCodable, RuntimeSwiftCodable, IdentifiableType
    {
        public typealias DecodingContext = VoidCodableContext
        public typealias EncodingContext = VoidCodableContext
        
        /// Could not lookup some information that is required to validate the transaction.
        case cannotLookup
        /// No validator found for the given unsigned transaction.
        case noUnsignedValidator
        /// Any other custom unknown validity that is not covered by this enum.
        case custom(UInt8)
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            let id = try decoder.decode(.enumCaseId)
            switch id {
            case 0: self = .cannotLookup
            case 1: self = .noUnsignedValidator
            case 2: self = try .custom(decoder.decode())
            default: throw decoder.enumCaseError(for: id)
            }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            switch self {
            case .cannotLookup: try encoder.encode(0, .enumCaseId)
            case .noUnsignedValidator: try encoder.encode(1, .enumCaseId)
            case .custom(let e):
                try encoder.encode(2, .enumCaseId)
                try encoder.encode(e)
            }
        }
        
        public init(from decoder: Swift.Decoder) throws {
            let container1 = try decoder.singleValueContainer()
            if let simple = try? container1.decode(String.self) {
                switch simple {
                case "CannotLookup": self = .cannotLookup
                case "NoUnsignedValidator": self = .noUnsignedValidator
                default:
                    throw Swift.DecodingError.dataCorruptedError(
                        in: container1, debugDescription: "Unknown case \(simple)"
                    )
                }
                return
            } else {
                let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
                guard let key = container2.allKeys.first else {
                    throw Swift.DecodingError.dataCorruptedError(
                        in: container1, debugDescription: "Empty case object"
                    )
                }
                guard key == .custom else {
                    throw Swift.DecodingError.dataCorruptedError(
                        forKey: key, in: container2, debugDescription: "Unknow enum case"
                    )
                }
                self = try .custom(container2.decode(UInt8.self, forKey: key))
            }
        }
        
        public func encode(to encoder: Swift.Encoder) throws {
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
        
        @inlinable
        public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
            .variant(variants: [
                .e(0, "CannotLookup"), .e(1, "NoUnsignedValidator"),
                .s(2, "Custom", registry.def(UInt8.self))
            ])
        }
    }
}

private extension CodableComplexKey where T == TransactionValidityError.UnknownTransaction {
    static let custom = Self(stringValue: "Custom")!
}

private extension CodableComplexKey where T == TransactionValidityError.InvalidTransaction {
    static let custom = Self(stringValue: "Custom")!
}

private extension CodableComplexKey where T == TransactionValidityError {
    static let invalid = Self(stringValue: "Invalid")!
    static let unknown = Self(stringValue: "Unknown")!
}

