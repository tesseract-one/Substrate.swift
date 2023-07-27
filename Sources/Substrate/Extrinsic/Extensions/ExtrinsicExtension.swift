//
//  ExtrinsicExtension.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import ScaleCodec

public protocol SignedExtensionsProvider<RC> {
    associatedtype RC: Config
    associatedtype TExtra
    associatedtype TAdditionalSigned
    associatedtype TSigningParams
    
    func params(overrides params: TSigningParams?) async throws -> TSigningParams
    func extra(params: TSigningParams) async throws -> TExtra
    func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned
    
    func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E) throws
    func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned, in encoder: inout E) throws
    func extra<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TExtra
    func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TAdditionalSigned
    
    mutating func setRootApi<R: RootApi<RC>>(api: R) throws
}

public protocol ExtraSigningParameters: Default {
    func override(overrides: Self?) throws -> Self
}

public protocol AnyNonceSigningParameter: ExtraSigningParameters {
    var hasNonce: Bool { get }
    func getNonce<N: UnsignedInteger>() throws -> N?
    mutating func setNonce<N: UnsignedInteger>(_ nonce: N?) throws
}

public protocol NonceSigningParameter<TNonce>: AnyNonceSigningParameter {
    associatedtype TNonce: UnsignedInteger
    var nonce: TNonce? { get set }
    func nonce(_ nonce: TNonce) -> Self
    static func nonce(_ nonce: TNonce) -> Self
}

public extension NonceSigningParameter {
    var hasNonce: Bool { nonce != nil }
    func getNonce<N: UnsignedInteger>() throws -> N? {
        guard N.self == TNonce.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TNonce.self, got: N.self)
        }
        return nonce as! N?
    }
    mutating func setNonce<N: UnsignedInteger>(_ nonce: N?) throws {
        guard N.self == TNonce.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TNonce.self, got: N.self)
        }
        self.nonce = nonce as! TNonce?
    }
}

public protocol AnyEraSigningParameter: ExtraSigningParameters {
    var hasEra: Bool { get }
    var hasBlockHash: Bool { get }
    func getEra<E: SomeExtrinsicEra>() throws -> E?
    mutating func setEra<E: SomeExtrinsicEra>(_ era: E?) throws
    func getBlockHash<H: Hash>() throws -> H?
    mutating func setBlockHash<H: Hash>(_ hash: H?) throws
}

public protocol EraSigningParameter<TEra, THash>: AnyEraSigningParameter {
    associatedtype TEra: SomeExtrinsicEra
    associatedtype THash: Hash
    
    var era: TEra? { get set }
    func era(_ era: TEra) -> Self
    static func era(_ era: TEra) -> Self
    
    var blockHash: THash? { get set }
    func blockHash(_ hash: THash) -> Self
    static func blockHash(_ hash: THash) -> Self
}

public extension EraSigningParameter {
    var hasEra: Bool { era != nil }
    var hasBlockHash: Bool { blockHash != nil }
    func getEra<E: SomeExtrinsicEra>() throws -> E? {
        guard E.self == TEra.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TEra.self, got: E.self)
        }
        return era as! E?
    }
    mutating func setEra<E: SomeExtrinsicEra>(_ era: E?) throws {
        guard E.self == TEra.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TEra.self, got: E.self)
        }
        self.era = era as! TEra?
    }
    func getBlockHash<H: Hash>() throws -> H? {
        guard H.self == THash.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: THash.self, got: H.self)
        }
        return blockHash as! H?
    }
    mutating func setBlockHash<H: Hash>(_ hash: H?) throws {
        guard H.self == THash.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: THash.self, got: H.self)
        }
        self.blockHash = hash as! THash?
    }
}

public protocol AnyPaymentSigningParameter: ExtraSigningParameters {
    var hasTip: Bool { get }
    func getTip<T: ValueRepresentable & Default>() throws -> T?
    mutating func setTip<T: ValueRepresentable & Default>(_ tip: T?) throws
}

public protocol PaymentSigningParameter<TPayment>: AnyPaymentSigningParameter {
    associatedtype TPayment: ValueRepresentable & Default
    
    var tip: TPayment? { get set }
    func tip(_ tip: TPayment) -> Self
    static func tip(_ tip: TPayment) -> Self
}

public extension PaymentSigningParameter {
    var hasTip: Bool { tip != nil }
    func getTip<T: ValueRepresentable & Default>() throws -> T? {
        guard T.self == TPayment.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TPayment.self, got: T.self)
        }
        return tip as! T?
    }
    mutating func setTip<T: ValueRepresentable & Default>(_ tip: T?) throws {
        guard T.self == TPayment.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TPayment.self, got: T.self)
        }
        self.tip = tip as! TPayment?
    }
}

public struct ExtrinsicExtensionId: Equatable, Hashable, RawRepresentable {
    public typealias RawValue = String
    public var rawValue: String
    public init(_ string: String) {
        self.rawValue = string
    }
    public init?(rawValue: String) {
        self.init(rawValue)
    }
    public static let checkSpecVersion = Self("CheckSpecVersion")
    public static let checkTxVersion = Self("CheckTxVersion")
    public static let checkGenesis = Self("CheckGenesis")
    public static let checkNonZeroSender = Self("CheckNonZeroSender")
    public static let checkNonce = Self("CheckNonce")
    public static let checkMortality = Self("CheckMortality")
    public static let checkWeight = Self("CheckWeight")
    public static let chargeTransactionPayment = Self("ChargeTransactionPayment")
    public static let prevalidateAttests = Self("PrevalidateAttests")
    public static let undefined = Self("UNDEFINED")
}
