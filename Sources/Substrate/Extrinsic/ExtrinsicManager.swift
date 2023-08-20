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

public protocol ExtrinsicDecoder {
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder, Extra: ExtrinsicExtra>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> Extrinsic<C, Extra>
    
    var version: UInt8 { get }
}

public protocol ExtrinsicManager<TConfig>: ExtrinsicDecoder {
    associatedtype TConfig: Config
    associatedtype TUnsignedParams
    associatedtype TSigningParams: ExtraSigningParameters
    associatedtype TUnsignedExtra: ExtrinsicExtra
    associatedtype TSigningExtra
    associatedtype TSignedExtra: ExtrinsicExtra
    
    func unsigned<C: Call, R: RootApi<TConfig>>(
        call: C, params: TUnsignedParams, for api: R
    ) async throws -> Extrinsic<C, TUnsignedExtra>
    func encode<C: Call, E: ScaleCodec.Encoder>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
                                                in encoder: inout E,
                                                runtime: any Runtime) throws

    func params<C: Call, R: RootApi<TConfig>>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        partial params: TSigningParams.TPartial,
        for api: R
    ) async throws -> TSigningParams
    
    func payload<C: Call, R: RootApi<TConfig>>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: TSigningParams, for api: R
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra>
    
    func encode<C: Call, E: ScaleCodec.Encoder>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                                                in encoder: inout E,
                                                runtime: any Runtime) throws
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        payload decoder: inout D, runtime: any Runtime
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra>
    
    func signed<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                         address: TConfig.TAddress,
                         signature: TConfig.TSignature,
                         runtime: any Runtime) throws -> Extrinsic<C, TSignedExtra>
    
    func encode<C: Call, E: ScaleCodec.Encoder>(signed extrinsic: Extrinsic<C, TSignedExtra>,
                                                in encoder: inout E,
                                                runtime: any Runtime) throws
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> AnyExtrinsic<C, Self>
    
    static var version: UInt8 { get }
}

public extension ExtrinsicManager {
    var version: UInt8 { Self.version }
    
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder, Extra: ExtrinsicExtra>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> Extrinsic<C, Extra> {
        guard Extrinsic<C, Extra>.self == AnyExtrinsic<C, Self>.self else {
            throw ExtrinsicCodingError.typeMismatch(expected: AnyExtrinsic<C, Self>.self,
                                                    got: Extrinsic<C, Extra>.self)
        }
        let decoded: AnyExtrinsic<C, Self> = try decode(from: &decoder, runtime: runtime)
        return decoded as! Extrinsic<C, Extra>
    }
}

