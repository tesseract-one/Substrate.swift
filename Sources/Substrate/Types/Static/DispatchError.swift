//
//  DispatchError.swift
//  
//
//  Created by Yehor Popovych on 24/08/2023.
//

import Foundation
import ScaleCodec

/// An error dispatching a transaction.
public enum DispatchError: SomeDispatchError, StaticCallError, Equatable,
                           ScaleCodec.Encodable
{
    /// Some unknown error occurred.
    case other
    /// Failed to lookup some data.
    case cannotLookup
    /// A bad origin.
    case badOrigin
    /// A custom error in a module.
    case module(ModuleErrorData)
    /// At least one consumer is remaining so the account cannot be destroyed.
    case consumerRemaining
    /// There are no providers so the account cannot be created.
    case noProviders
    /// There are too many consumers so the account cannot be created.
    case tooManyConsumers
    /// An error to do with tokens.
    case token(TokenError)
    /// An arithmetic error.
    case arithmetic(ArithmeticError)
    /// The number of transactional layers has been reached, or we are not in a transactional
    /// layer.
    case transactional(TransactionalError)
    /// Resources exhausted, e.g. attempt to read/write data which is too large to manipulate.
    case exhausted
    /// The state is corrupt; this is generally not going to fix itself.
    case corruption
    /// Some resource (e.g. a preimage) is unavailable right now. This might fix itself later.
    case unavailable
    /// Root origin is not allowed.
    case rootNotAllowed
    
    public typealias TModuleError = ModuleError
    
    public var isModuleError: Bool {
        switch self {
        case .module(_): return true
        default: return false
        }
    }
    
    public var moduleError: ModuleError { get throws {
        switch self {
        case .module(let data):
            return try ModuleError(pallet: data.index,
                                   error: data.error[0],
                                   metadata: data._runtime.metadata)
        default:
            throw FrameTypeError.paramMismatch(for: "DispatchError",
                                               index: -1, expected: "ModuleError",
                                               got: "\(self)")
        }
    }}
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        let id = try decoder.decode(.enumCaseId)
        switch id {
        case 0: self = .other
        case 1: self = .cannotLookup
        case 2: self = .badOrigin
        case 3: self = try .module(runtime.decode(from: &decoder))
        case 4: self = .consumerRemaining
        case 5: self = .noProviders
        case 6: self = .tooManyConsumers
        case 7: self = try .token(decoder.decode())
        case 8: self = try .arithmetic(decoder.decode())
        case 9: self = try .transactional(decoder.decode())
        case 10: self = .exhausted
        case 11: self = .corruption
        case 12: self = .unavailable
        case 13: self = .rootNotAllowed
        default: throw decoder.enumCaseError(for: id)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        switch self {
        case .other: try encoder.encode(0, .enumCaseId)
        case .cannotLookup: try encoder.encode(1, .enumCaseId)
        case .badOrigin: try encoder.encode(2, .enumCaseId)
        case .module(let data):
            try encoder.encode(3, .enumCaseId)
            try encoder.encode(data)
        case .consumerRemaining: try encoder.encode(4, .enumCaseId)
        case .noProviders: try encoder.encode(5, .enumCaseId)
        case .tooManyConsumers: try encoder.encode(6, .enumCaseId)
        case .token(let err):
            try encoder.encode(7, .enumCaseId)
            try encoder.encode(err)
        case .arithmetic(let err):
            try encoder.encode(8, .enumCaseId)
            try encoder.encode(err)
        case .transactional(let err):
            try encoder.encode(9, .enumCaseId)
            try encoder.encode(err)
        case .exhausted: try encoder.encode(10, .enumCaseId)
        case .corruption: try encoder.encode(11, .enumCaseId)
        case .unavailable: try encoder.encode(12, .enumCaseId)
        case .rootNotAllowed: try encoder.encode(13, .enumCaseId)
        }
    }
    
    public static var definition: TypeDefinition {
        .variant(variants: [
            .e(0, "Other"), .e(1, "CannotLookup"), .e(2, "BadOrigin"),
            .s(3, "Module", ModuleErrorData.definition), .e(4, "ConsumerRemaining"),
            .e(5, "NoProviders"), .e(6, "TooManyConsumers"),
            .s(7, "Token", TokenError.definition),
            .s(8, "Arithmetic", ArithmeticError.definition),
            .s(9, "Transactional", TransactionalError.definition),
            .e(10, "Exhausted"), .e(11, "Corruption"), .e(12, "Unavailable"),
            .e(13, "RootNotAllowed")
        ])
    }
}

public extension DispatchError {
    /// Reason why a pallet call failed.
    struct ModuleErrorData: Equatable, RuntimeDecodable, ScaleCodec.Encodable,
                            RuntimeSwiftCodable, Swift.Encodable, IdentifiableType
    {
        /// Module index, matching the metadata module index.
        public let index: UInt8
        /// Module specific error value. 4 bytes
        public let error: Data
        
        fileprivate let _runtime: any Runtime
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
            _runtime = runtime
            index = try decoder.decode()
            error = try decoder.decode(.fixed(4))
        }
        
        public init(from decoder: Swift.Decoder, runtime: Runtime) throws {
            let container = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            index = try container.decode(UInt8.self, forKey: .index)
            error = try container.decode(Data.self, forKey: .error)
            _runtime = runtime
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(index)
            try encoder.encode(error, .fixed(4))
        }
        
        public func encode(to encoder: Swift.Encoder) throws {
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(index, forKey: .index)
            try container.encode(error, forKey: .error)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.index == rhs.index && lhs.error == rhs.error
        }
        
        public static var definition: TypeDefinition {
            .composite(fields: [.v(UInt8.definition), .v(.data(count: 4))])
        }
    }
    
    enum TokenError: UInt8, CaseIterable, ScaleCodec.Codable,
                     RuntimeCodable, Swift.Codable, IdentifiableType
    {
        /// Funds are unavailable.
        case fundsUnavailable
        /// Some part of the balance gives the only provider reference to the account and thus cannot
        /// be (re)moved.
        case onlyProvider
        /// Account cannot exist with the funds that would be given.
        case belowMinimum
        /// Account cannot be created.
        case cannotCreate
        /// The asset in question is unknown.
        case unknownAsset
        /// Funds exist but are frozen.
        case frozen
        /// Operation is not supported by the asset.
        case unsupported
        /// Account cannot be created for a held balance.
        case cannotCreateHold
        /// Withdrawal would cause unwanted loss of account.
        case notExpendable
//        /// Account cannot receive the assets.
        case blocked
    }

    enum ArithmeticError: UInt8, CaseIterable, ScaleCodec.Codable,
                          RuntimeCodable, Swift.Codable, IdentifiableType
    {
        case underflow
        case overflow
        case divisionByZero
    }

    /// Errors related to transactional storage layers.
    enum TransactionalError: UInt8, CaseIterable, ScaleCodec.Codable,
                             RuntimeCodable, Swift.Codable, IdentifiableType
    {
        /// Too many transactional layers have been spawned.
        case limitReached
        /// A transactional layer was expected, but does not exist.
        case noLayer
    }
}

extension DispatchError: RuntimeSwiftCodable, Swift.Encodable {
    public init(from decoder: Swift.Decoder, runtime: Runtime) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "Other": self = .other
            case "CannotLookup": self = .cannotLookup
            case "BadOrigin": self = .badOrigin
            case "ConsumerRemaining": self = .consumerRemaining
            case "NoProviders": self = .noProviders
            case "TooManyConsumers": self = .tooManyConsumers
            case "Exhausted": self = .exhausted
            case "Corruption": self = .corruption
            case "Unavailable": self = .unavailable
            case "RootNotAllowed": self = .rootNotAllowed
            default:
                throw Swift.DecodingError.dataCorruptedError(in: container1,
                                                             debugDescription: "Unknown case \(simple)")
            }
            return
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw Swift.DecodingError.dataCorruptedError(in: container1,
                                                             debugDescription: "Empty case object")
            }
            switch key {
            case .module:
                let m = try container2.decode(ModuleErrorData.self, forKey: key,
                                              context: .init(runtime: runtime))
                self = .module(m)
            case .token:
                self = try .token(container2.decode(TokenError.self, forKey: key))
            case .arithmetic:
                self = try .arithmetic(container2.decode(ArithmeticError.self, forKey: key))
            case .transactional:
                self = try .transactional(container2.decode(TransactionalError.self, forKey: key))
            default:
                throw Swift.DecodingError.dataCorruptedError(forKey: key,
                                                             in: container2,
                                                             debugDescription: "Unknow enum case")
            }
        }
    }
    
    public func encode(to encoder: Swift.Encoder) throws {
        switch self {
        case .other:
            var container = encoder.singleValueContainer()
            try container.encode("Other")
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
        case .tooManyConsumers:
            var container = encoder.singleValueContainer()
            try container.encode("TooManyConsumers")
        case .exhausted:
            var container = encoder.singleValueContainer()
            try container.encode("Exhausted")
        case .corruption:
            var container = encoder.singleValueContainer()
            try container.encode("Corruption")
        case .unavailable:
            var container = encoder.singleValueContainer()
            try container.encode("Unavailable")
        case .rootNotAllowed:
            var container = encoder.singleValueContainer()
            try container.encode("RootNotAllowed")
        case .module(let data):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(data, forKey: .module)
        case .token(let err):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(err, forKey: .token)
        case .arithmetic(let err):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(err, forKey: .arithmetic)
        case .transactional(let err):
            var container = encoder.container(keyedBy: CodableComplexKey<Self>.self)
            try container.encode(err, forKey: .transactional)
        }
    }
}

private extension CodableComplexKey where T == DispatchError.ModuleErrorData {
    static let index = Self(stringValue: "index")!
    static let error = Self(stringValue: "error")!
}

private extension CodableComplexKey where T == DispatchError {
    static let module = Self(stringValue: "Module")!
    static let token = Self(stringValue: "Token")!
    static let arithmetic = Self(stringValue: "Arithmetic")!
    static let transactional = Self(stringValue: "Transactional")!
}

