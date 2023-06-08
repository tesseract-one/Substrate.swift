//
//  ExtrinsicExtension.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import ScaleCodec

public protocol SignedExtensionsProvider<RT> {
    associatedtype RT: Config
    associatedtype TExtra
    associatedtype TAdditionalSigned
    associatedtype TSigningParams
    
    func params(merged params: TSigningParams?) async throws -> TSigningParams
    func extra(params: TSigningParams) async throws -> TExtra
    func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned
    
    func encode(extra: TExtra, in encoder: ScaleEncoder) throws
    func encode(additionalSigned: TAdditionalSigned, in encoder: ScaleEncoder) throws
    func extra(from decoder: ScaleDecoder) throws -> TExtra
    func additionalSigned(from decoder: ScaleDecoder) throws -> TAdditionalSigned
    
    mutating func setSubstrate<S: SomeSubstrate<RT>>(substrate: S) throws
}

public protocol AnyNonceSigningParameter {
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

public protocol AnyEraSigningParameter {
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

public protocol AnyPaymentSigningParameter {
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

public struct AnySigningParams<RT: Config> {
    private var params: [String: Any]
    
    public init() {
        self.params = [:]
    }
    
    public subscript(key: String) -> Any? {
        get { params[key] }
        set { params[key] = newValue }
    }
}

extension AnySigningParams: NonceSigningParameter {
    public typealias TNonce = RT.TIndex
    public var nonce: TNonce? {
        get { self["nonce"] as? TNonce }
        set { self["nonce"] = newValue }
    }
    public func nonce(_ nonce: TNonce) -> Self {
        var new = self
        new.nonce = nonce
        return new
    }
    public static func nonce(_ nonce: TNonce) -> Self {
        var new = Self()
        new.nonce = nonce
        return new
    }
}

extension AnySigningParams: EraSigningParameter {
    public typealias TEra = RT.TExtrinsicEra
    public typealias THash = RT.TBlock.THeader.THasher.THash
    public var era: TEra? {
        get { params["era"] as? TEra }
        set { params["era"] = newValue }
    }
    public func era(_ era: TEra) -> Self {
        var new = self
        new.era = era
        return new
    }
    public static func era(_ era: TEra) -> Self {
        var new = Self()
        new.era = era
        return new
    }
    public var blockHash: THash? {
        get { params["blockHash"] as? THash }
        set { params["blockHash"] = newValue }
    }
    public func blockHash(_ hash: THash) -> Self {
        var new = self
        new.blockHash = hash
        return new
    }
    public static func blockHash(_ hash: THash) -> Self {
        var new = Self()
        new.blockHash = hash
        return new
    }
}

extension AnySigningParams: PaymentSigningParameter {
    public typealias TPayment = RT.TExtrinsicPayment
    public var tip: TPayment? {
        get { self["tip"] as? TPayment }
        set { self["tip"] = newValue }
    }
    public func tip(_ tip: TPayment) -> Self {
        var new = self
        new.tip = tip
        return new
    }
    public static func tip(_ tip: TPayment) -> Self {
        var new = Self()
        new.tip = tip
        return new
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
}

public protocol DynamicExtrinsicExtension {
    var identifier: ExtrinsicExtensionId { get }
    
    func extra<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId>
    
    func additionalSigned<S: SomeSubstrate>(
        substrate: S, params: AnySigningParams<S.RC>, id: RuntimeTypeId
    ) async throws -> Value<RuntimeTypeId>
}

public class DynamicSignedExtensionsProvider<RT: Config>: SignedExtensionsProvider {
    public typealias RT = RT
    public typealias TExtra = Value<RuntimeTypeId>
    public typealias TAdditionalSigned = [Value<RuntimeTypeId>]
    public typealias TSigningParams = AnySigningParams<RT>
    
    private var _substrate: (any _SomeSubstrateWrapper<RT>)!
    
    public let extensions: [String: DynamicExtrinsicExtension]
    public let version: UInt8
    
    public init(extensions: [DynamicExtrinsicExtension], version: UInt8) {
        self.extensions = Dictionary(uniqueKeysWithValues: extensions.map { ($0.identifier.rawValue, $0) })
        self.version = version
    }
    
    public func params(merged params: TSigningParams?) async throws -> TSigningParams {
        params ?? AnySigningParams()
    }
    
    public func defaultParams() async throws -> TSigningParams { AnySigningParams() }
    
    public func extra(params: TSigningParams) async throws -> TExtra {
        try await _substrate.extra(params: params)
    }
    
    public func additionalSigned(params: TSigningParams) async throws -> TAdditionalSigned {
        try await _substrate.additionalSigned(params: params)
    }
    
    public func encode(extra: TExtra, in encoder: ScaleEncoder) throws {
        try extra.encode(in: encoder, runtime: _substrate.runtime)
    }
    
    public func encode(additionalSigned: TAdditionalSigned, in encoder: ScaleEncoder) throws {
        guard additionalSigned.count == _substrate.additionalSignedTypes.count else {
            throw ExtrinsicCodingError.badExtrasCount(expected: _substrate.additionalSignedTypes.count,
                                                      got: additionalSigned.count)
        }
        for ext in additionalSigned {
            try ext.encode(in: encoder, runtime: _substrate.runtime)
        }
    }
    
    public func extra(from decoder: ScaleDecoder) throws -> TExtra {
        try TExtra(from: decoder, as: _substrate.extraType, runtime: _substrate.runtime)
    }
    
    public func additionalSigned(from decoder: ScaleDecoder) throws -> TAdditionalSigned {
        try _substrate.additionalSignedTypes.map { tId in
            try Value(from: decoder, as: tId, runtime: _substrate.runtime)
        }
    }
    
    public func setSubstrate<S: SomeSubstrate<RT>>(substrate: S) throws {
        self._substrate = try _SubstrateWrapper(substrate: substrate, version: version, extensions: extensions)
    }
}

private protocol _SomeSubstrateWrapper<RT> {
    associatedtype RT: Config
    
    var extraType: RuntimeTypeId { get }
    var additionalSignedTypes: [RuntimeTypeId] { get }
    var runtime: any Runtime { get }
    
    func extra(params: AnySigningParams<RT>) async throws -> Value<RuntimeTypeId>
    func additionalSigned(params: AnySigningParams<RT>) async throws -> [Value<RuntimeTypeId>]
}

private struct _SubstrateWrapper<ST: SomeSubstrate>: _SomeSubstrateWrapper {
    typealias RT = ST.RC
    
    weak var substrate: ST!
    let extensions: [(ext: DynamicExtrinsicExtension, eId: RuntimeTypeId, aId: RuntimeTypeId)]
    
    let extraType: RuntimeTypeId
    let additionalSignedTypes: [RuntimeTypeId]
    @inlinable
    var runtime: any Runtime { substrate.runtime }
    
    init(substrate: ST, version: UInt8, extensions: [String: DynamicExtrinsicExtension]) throws {
        guard substrate.runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: substrate.runtime.metadata.extrinsic.version)
        }
        self.extraType = try substrate.runtime.extrinsicExtraType.id
        self.extensions = try substrate.runtime.metadata.extrinsic.extensions.map { info in
            guard let ext = extensions[info.identifier] else {
                throw  ExtrinsicCodingError.unknownExtension(identifier: info.identifier)
            }
            return (ext, info.type.id, info.additionalSigned.id)
        }
        self.additionalSignedTypes = self.extensions.map { $0.aId }
        self.substrate = substrate
    }
    
    func extra(params: AnySigningParams<ST.RC>) async throws -> Value<RuntimeTypeId> {
        var extra: [Value<RuntimeTypeId>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.ext.extra(substrate: substrate, params: params, id: ext.eId))
        }
        return Value(value: .sequence(extra), context: extraType)
    }
    
    func additionalSigned(params: AnySigningParams<ST.RC>) async throws -> [Value<RuntimeTypeId>] {
        var extra: [Value<RuntimeTypeId>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.ext.additionalSigned(substrate: substrate, params: params, id: ext.aId))
        }
        return extra
    }
}