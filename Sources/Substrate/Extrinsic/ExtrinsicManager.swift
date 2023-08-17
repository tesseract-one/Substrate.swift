//
//  ExtrinsicManager.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public typealias AnyExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, Either<M.TUnsignedExtra, M.TSignedExtra>>
public typealias SignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TSignedExtra>
public typealias UnsignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TUnsignedExtra>
public typealias SigningPayload<C: Call, M: ExtrinsicManager> = ExtrinsicSignPayload<C, M.TSigningExtra>

public protocol ExtrinsicManager<RC> {
    associatedtype RC: Config
    associatedtype TUnsignedParams
    associatedtype TSigningParams: ExtraSigningParameters
    associatedtype TUnsignedExtra: ExtrinsicExtra
    associatedtype TSigningExtra
    associatedtype TSignedExtra: ExtrinsicExtra
    
    var version: UInt8 { get }
    
    func unsigned<C: Call>(call: C, params: TUnsignedParams) async throws -> Extrinsic<C, TUnsignedExtra>
    func encode<C: Call, E: ScaleCodec.Encoder>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
                                                in encoder: inout E) throws
    
    func params<C: Call>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        partial params: TSigningParams.TPartial
    ) async throws -> TSigningParams
    
    func payload<C: Call>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: TSigningParams
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra>
    func encode<C: Call, E: ScaleCodec.Encoder>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                                                in encoder: inout E) throws
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        payload decoder: inout D
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra>
    
    func signed<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                         address: RC.TAddress,
                         signature: RC.TSignature) throws -> Extrinsic<C, TSignedExtra>
    func encode<C: Call, E: ScaleCodec.Encoder>(signed extrinsic: Extrinsic<C, TSignedExtra>,
                                                in encoder: inout E) throws
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D
    ) throws -> AnyExtrinsic<C, Self>
    
    mutating func setRootApi<A: RootApi<RC>>(api: A) throws
    
    static var version: UInt8 { get }
    static func get(from runtime: any Runtime) throws -> Self
}

public extension ExtrinsicManager {
    var version: UInt8 { Self.version }
    
    static func get(from runtime: any Runtime) throws -> Self where RC: Config {
        guard let extended = runtime as? ExtendedRuntime<RC> else {
            throw ExtrinsicCodingError.unsupportedSubstrate(reason: "Runtime is not ER or different config")
        }
        guard let manager = extended.extrinsicManager as? Self else {
            throw ExtrinsicCodingError.unsupportedSubstrate(reason: "Different manager in runtime")
        }
        return manager
    }
}

