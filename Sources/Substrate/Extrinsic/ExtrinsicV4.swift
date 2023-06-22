//
//  ExtrinsicV4.swift
//  
//
//  Created by Yehor Popovych on 13.01.2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicV4Extra<Addr, Sig, Extra>: ExtrinsicExtra, CustomStringConvertible {
    public var isSigned: Bool { true }
    
    public let address: Addr
    public let signature: Sig
    public let extra: Extra
    
    public init(address: Addr, signature: Sig, extra: Extra) {
        self.address = address
        self.signature = signature
        self.extra = extra
    }
    
    public var description: String {
        "{address: \(address), signature: \(signature), extra: \(extra)}"
    }
}

public class ExtrinsicV4Manager<RC: Config, SE: SignedExtensionsProvider<RC>>: ExtrinsicManager {
    public typealias RT = RC
    public typealias TUnsignedParams = Void
    public typealias TSigningParams = SE.TSigningParams
    public typealias TUnsignedExtra = Nothing
    public typealias TSigningExtra = (extra: SE.TExtra, additional: SE.TAdditionalSigned)
    public typealias TSignedExtra = ExtrinsicV4Extra<RC.TAddress, RC.TSignature, SE.TExtra>
    
    private var extensions: SE
    private var runtime: (any Runtime)!

    public init(extensions: SE) {
        self.extensions = extensions
    }
    
    public func unsigned<C: Call>(call: C, params: TUnsignedParams) async throws -> Extrinsic<C, TUnsignedExtra> {
        Extrinsic(call: call, extra: nil)
    }
    
    public func encode<C: Call>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>, in encoder: ScaleEncoder) throws {
        let inner = runtime.encoder()
        try inner.encode(Self.version & 0b0111_1111)
        try extrinsic.call.encode(in: inner, runtime: runtime)
        try encoder.encode(inner.output)
    }
    
    public func params<C: Call>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        overrides: TSigningParams?
    ) async throws -> TSigningParams {
        try await extensions.params(merged: overrides)
    }
    
    public func payload<C: Call>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: TSigningParams
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra> {
        return try await ExtrinsicSignPayload(call: extrinsic.call,
                                              extra: (extensions.extra(params: params),
                                                      extensions.additionalSigned(params: params)))
    }
    
    public func encode<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>, in encoder: ScaleEncoder) throws {
        try payload.call.encode(in: encoder, runtime: runtime)
        try extensions.encode(extra: payload.extra.extra, in: encoder)
        try extensions.encode(additionalSigned: payload.extra.additional, in: encoder)
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>(
        payload decoder: ScaleDecoder
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra> {
        let call = try C(from: decoder, runtime: runtime)
        let extra = try extensions.extra(from: decoder)
        let additional = try extensions.additionalSigned(from: decoder)
        return ExtrinsicSignPayload(call: call, extra: (extra, additional))
    }
    
    public func signed<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                                address: RT.TAddress,
                                signature: RT.TSignature) throws -> Extrinsic<C, TSignedExtra> {
        Extrinsic(call: payload.call,
                  extra: ExtrinsicV4Extra(address: address, signature: signature, extra: payload.extra.extra))
    }
    
    public func encode<C: Call>(signed extrinsic: Extrinsic<C, TSignedExtra>, in encoder: ScaleEncoder) throws {
        let inner = runtime.encoder()
        try inner.encode(Self.version | 0b1000_0000)
        try extrinsic.extra.address.encode(in: inner, runtime: runtime)
        try extrinsic.extra.signature.encode(in: inner, runtime: runtime)
        try extensions.encode(extra: extrinsic.extra.extra, in: inner)
        try extrinsic.call.encode(in: inner, runtime: runtime)
        try encoder.encode(inner.output)
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>(
        from decoder: ScaleDecoder
    ) throws -> Extrinsic<C, Either<TUnsignedExtra, TSignedExtra>> {
        let decoder = try runtime.decoder(with: decoder.decode(Data.self))
        var version = try decoder.decode(UInt8.self)
        let isSigned = version & 0b1000_0000 > 0
        version &= 0b0111_1111
        guard version == Self.version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(supported: Self.version,
                                                           got: version)
        }
        if isSigned {
            let address = try RC.TAddress(from: decoder, runtime: runtime)
            let signature = try RC.TSignature(from: decoder, runtime: runtime)
            let extra = try extensions.extra(from: decoder)
            return Extrinsic(call: try C(from: decoder, runtime: runtime),
                             extra: .right(ExtrinsicV4Extra(address: address, signature: signature, extra: extra)))
        } else {
            return Extrinsic(call: try C(from: decoder, runtime: runtime),
                             extra: .left(nil))
        }
    }
    
    public func setSubstrate<S: SomeSubstrate<RT>>(substrate: S) throws {
        try self.extensions.setSubstrate(substrate: substrate)
        self.runtime = substrate.runtime
    }
    
    public static var version: UInt8 { 4 }
}
