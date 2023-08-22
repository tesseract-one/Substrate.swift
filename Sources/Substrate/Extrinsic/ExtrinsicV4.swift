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

public class ExtrinsicV4Manager<SE: SignedExtensionsProvider>: ExtrinsicManager {
    public typealias TConfig = SE.TConfig
    public typealias TAddress = SE.TConfig.TAddress
    public typealias TSignature = SE.TConfig.TSignature
    public typealias TUnsignedParams = Void
    public typealias TUnsignedExtra = Nothing
    public typealias TSigningExtra = (extra: SE.TExtra, additional: SE.TAdditionalSigned)
    public typealias TSignedExtra = ExtrinsicV4Extra<TAddress, TSignature, SE.TExtra>
    
    private var extensions: SE

    public init(extensions: SE) {
        self.extensions = extensions
    }
    
    public func unsigned<C: Call, R: RootApi>(
        call: C, params: TUnsignedParams, for api: R
    ) async throws -> Extrinsic<C, TUnsignedExtra> where SBC<R.RC> == TConfig {
        Extrinsic(call: call, extra: nil)
    }
    
    public func encode<C: Call, E: ScaleCodec.Encoder>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
                                                       in encoder: inout E,
                                                       runtime: any Runtime) throws
    {
        var inner = runtime.encoder()
        try inner.encode(Self.version & 0b0111_1111)
        try runtime.encode(call: extrinsic.call, in: &inner)
        try encoder.encode(inner.output)
    }
    
    public func params<C: Call, R: RootApi>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        partial params: SBT<TConfig>.SigningParamsPartial, for api: R
    ) async throws -> SBT<TConfig>.SigningParams where SBC<R.RC> == TConfig {
        try await extensions.params(partial: params, for: api)
    }
    
    public func payload<C: Call, R: RootApi>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: SBT<TConfig>.SigningParams, for api: R
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra> where SBC<R.RC> == TConfig {
        return try await ExtrinsicSignPayload(call: extrinsic.call,
                                              extra: (extensions.extra(params: params, for: api),
                                                      extensions.additionalSigned(params: params, for: api)))
    }
    
    public func encode<C: Call, E: ScaleCodec.Encoder>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                                                       in encoder: inout E,
                                                       runtime: any Runtime) throws
    {
        try runtime.encode(call: payload.call, in: &encoder)
        try extensions.encode(extra: payload.extra.extra, in: &encoder, runtime: runtime)
        try extensions.encode(additionalSigned: payload.extra.additional, in: &encoder, runtime: runtime)
    }
    
    public func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        payload decoder: inout D, runtime: any Runtime
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra> {
        let call = try runtime.decode(call: C.self, from: &decoder)
        let extra = try extensions.extra(from: &decoder, runtime: runtime)
        let additional = try extensions.additionalSigned(from: &decoder, runtime: runtime)
        return ExtrinsicSignPayload(call: call, extra: (extra, additional))
    }
    
    public func signed<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                                address: TAddress,
                                signature: TSignature,
                                runtime: any Runtime) throws -> Extrinsic<C, TSignedExtra>
    {
        Extrinsic(call: payload.call,
                  extra: ExtrinsicV4Extra(address: address, signature: signature, extra: payload.extra.extra))
    }
    
    public func encode<C: Call, E: ScaleCodec.Encoder>(signed extrinsic: Extrinsic<C, TSignedExtra>,
                                                       in encoder: inout E,
                                                       runtime: any Runtime) throws
    {
        var inner = runtime.encoder()
        try inner.encode(Self.version | 0b1000_0000)
        try runtime.encode(address: extrinsic.extra.address, in: &inner)
        try runtime.encode(signature: extrinsic.extra.signature, in: &inner)
        try extensions.encode(extra: extrinsic.extra.extra, in: &inner, runtime: runtime)
        try runtime.encode(call: extrinsic.call, in: &inner)
        try encoder.encode(inner.output)
    }
    
    public func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime
    ) throws -> Extrinsic<C, Either<TUnsignedExtra, TSignedExtra>> {
        var decoder = try runtime.decoder(with: decoder.decode(Data.self))
        var version = try decoder.decode(UInt8.self)
        let isSigned = version & 0b1000_0000 > 0
        version &= 0b0111_1111
        guard version == Self.version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(supported: Self.version,
                                                           got: version)
        }
        if isSigned {
            let address = try runtime.decode(address: TAddress.self, from: &decoder)
            let signature = try runtime.decode(signature: TSignature.self, from: &decoder)
            let extra = try extensions.extra(from: &decoder, runtime: runtime)
            return Extrinsic(call: try runtime.decode(call: C.self, from: &decoder),
                             extra: .right(ExtrinsicV4Extra(address: address, signature: signature, extra: extra)))
        } else {
            return Extrinsic(call: try runtime.decode(call: C.self, from: &decoder),
                             extra: .left(nil))
        }
    }
    
    public func validate(runtime: any Runtime) throws {
        guard runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: runtime.metadata.extrinsic.version
            )
        }
        try TAddress.validate(runtime: runtime, type: runtime.types.address.id).get()
        try TSignature.validate(runtime: runtime, type: runtime.types.signature.id).get()
        try extensions.validate(runtime: runtime).get()
    }
    
    public static var version: UInt8 { 4 }
}
