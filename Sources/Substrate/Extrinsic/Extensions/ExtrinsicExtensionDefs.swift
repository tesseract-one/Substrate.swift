//
//  ExtrinsicExtensionDefs.swift
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
    associatedtype TSigningParams: ExtraSigningParameters
    
    func params(partial params: TSigningParams.TPartial) async throws -> TSigningParams
    func extra(params: TSigningParams) async throws -> TExtra
    func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned
    
    func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E) throws
    func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned, in encoder: inout E) throws
    func extra<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TExtra
    func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D) throws -> TAdditionalSigned
    
    mutating func setRootApi<R: RootApi<RC>>(api: R) throws
}

public protocol ExtraSigningParameters {
    associatedtype TPartial: Default
    init(partial: TPartial) throws
}

public protocol AnyAccountPartialSigningParameter {
    mutating func setAccount<A: AccountId>(_ account: A?) throws
}

public protocol NoncePartialSigningParameter<TNonce, TAccountId>: AnyAccountPartialSigningParameter {
    associatedtype TNonce: UnsignedInteger
    associatedtype TAccountId: AccountId
    
    var account: TAccountId? { get set }
    var nonce: TNonce? { get set }
    
    func nonce(_ nonce: TNonce) -> Self
    static func nonce(_ nonce: TNonce) -> Self
}

public protocol NonceSigningParameters: ExtraSigningParameters
    where TPartial: NoncePartialSigningParameter
{
    var nonce: TPartial.TNonce { get }
}

public extension NoncePartialSigningParameter {
    mutating func setAccount<A: AccountId>(_ account: A?) throws {
        guard A.self == TAccountId.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: TAccountId.self, got: A.self)
        }
        self.account = account as! TAccountId?
    }
}

public protocol EraPartialSigningParameter<TEra, THash> {
    associatedtype TEra: SomeExtrinsicEra
    associatedtype THash: Hash
    
    var era: TEra? { get set }
    func era(_ era: TEra) -> Self
    static func era(_ era: TEra) -> Self
    
    var blockHash: THash? { get set }
    func blockHash(_ hash: THash) -> Self
    static func blockHash(_ hash: THash) -> Self
}

public protocol EraSigningParameters: ExtraSigningParameters
    where TPartial: EraPartialSigningParameter
{
    var era: TPartial.TEra { get }
    var blockHash: TPartial.THash { get }
}

public protocol PaymentPartialSigningParameter<TPayment> {
    associatedtype TPayment: ValueRepresentable & Default
    
    var tip: TPayment? { get set }
    func tip(_ tip: TPayment) -> Self
    static func tip(_ tip: TPayment) -> Self
}

public protocol PaymentSigningParameters: ExtraSigningParameters
    where TPartial: PaymentPartialSigningParameter
{
    var tip: TPartial.TPayment { get }
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
