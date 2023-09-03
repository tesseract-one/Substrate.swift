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

public protocol SignedExtensionsProvider {
    associatedtype TConfig: BasicConfig
    associatedtype TParams: ExtraSigningParameters
    associatedtype TExtra
    associatedtype TAdditionalSigned
    
    func params<R: RootApi>(
        partial params: TParams.TPartial, for api: R
    ) async throws -> TParams where SBC<R.RC> == TConfig
    
    func extra<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TExtra where SBC<R.RC> == TConfig
    
    func additionalSigned<R: RootApi>(
        params: TParams, for api: R
    ) async throws -> TAdditionalSigned where SBC<R.RC> == TConfig
    
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
    ) -> Result<Void, Either<ExtrinsicCodingError, TypeError>>
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

