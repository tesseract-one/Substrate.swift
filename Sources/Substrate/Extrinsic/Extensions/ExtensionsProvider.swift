//
//  ExtensionsProvider.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public protocol ExtraSigningParameters {
    associatedtype TPartial: Default
    var partial: TPartial { get }
    init(partial: TPartial) throws
}

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

public protocol ExtrinsicSignedExtension {
    var identifier: ExtrinsicExtensionId { get }
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

