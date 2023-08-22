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

public protocol SignedExtensionsProvider where TConfig.TSigningParams: ExtraSigningParameters {
    associatedtype TConfig: Config
    associatedtype TExtra
    associatedtype TAdditionalSigned
    
    func params<R: RootApi<TConfig>>(partial params: TConfig.TSigningParams.TPartial,
                                     for api: R) async throws -> TConfig.TSigningParams
    
    func extra<R: RootApi<TConfig>>(params: TConfig.TSigningParams,
                                    for api: R) async throws -> TExtra
    
    func additionalSigned<R: RootApi<TConfig>>(params: TConfig.TSigningParams,
                                               for api: R) async throws -> TAdditionalSigned
    
    func encode<E: ScaleCodec.Encoder>(extra: TExtra, in encoder: inout E,
                                       runtime: any Runtime) throws
    func encode<E: ScaleCodec.Encoder>(additionalSigned: TAdditionalSigned,
                                       in encoder: inout E,
                                       runtime: any Runtime) throws
    func extra<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws -> TExtra
    func additionalSigned<D: ScaleCodec.Decoder>(from decoder: inout D,
                                                 runtime: any Runtime) throws -> TAdditionalSigned
    
    func validate(
        runtime: any Runtime
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeValidationError>>
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
}

