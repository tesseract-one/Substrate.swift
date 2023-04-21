//
//  ExtrinsicV4.swift
//  
//
//  Created by Yehor Popovych on 13.01.2023.
//

import Foundation
import ScaleCodec

public class ExtrinsicV4Manager<RC: RuntimeConfig, SE: SignedExtensionsProvider<RC>>: ExtrinsicManager {
    public typealias RT = RC
    public typealias TUnsignedParams = Void
    public typealias TSigningParams = SE.TSigningParams
    public typealias TUnsignedExtra = Void
    public typealias TSigningExtra = (extra: SE.TExtra, additional: SE.TAdditionalSigned)
    public typealias TSignedExtra = (address: RT.TAddress, signature: RT.TSignature, extra: SE.TExtra)
    
    private var extensions: SE
    private var runtime: (any Runtime)!
    private var dynamicTypes: LazyProperty<(addr: RuntimeTypeId, sig: RuntimeTypeId)>!
    
    public init(extensions: SE) {
        self.extensions = extensions
        self.dynamicTypes = nil
    }
    
    public func build<C: Call>(
        unsigned call: C, params: TUnsignedParams
    ) async throws -> Extrinsic<C, TUnsignedExtra> {
        Extrinsic(call: call, extra: (), signed: false)
    }
    
    public func encode<C: Call>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>, in encoder: ScaleEncoder) throws {
        let inner = runtime.encoder()
        try inner.encode(Self.version & 0b0111_1111)
        try extrinsic.call.encode(in: inner, runtime: runtime)
        try encoder.encode(inner.output)
    }
    
    public func build<C: Call>(
        payload extrinsic: Extrinsic<C, TUnsignedExtra>,
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
    
    public func build<C: Call>(signed payload: ExtrinsicSignPayload<C, TSigningExtra>,
                               address: RT.TAddress,
                               signature: RT.TSignature) throws -> Extrinsic<C, TSignedExtra> {
        Extrinsic(call: payload.call, extra: (address, signature, payload.extra.extra), signed: true)
    }
    
    public func encode<C: Call>(signed extrinsic: Extrinsic<C, TSignedExtra>, in encoder: ScaleEncoder) throws {
        let inner = runtime.encoder()
        try inner.encode(Self.version | 0b1000_0000)
        try extrinsic.extra.address.asValue().encode(in: inner,
                                                     runtime: runtime) { _ in
            try self.dynamicTypes.value.addr
        }
        try extrinsic.extra.signature.encode(in: inner,
                                             runtime: runtime) { _ in
            try self.dynamicTypes.value.sig
        }
        try extensions.encode(extra: extrinsic.extra.extra, in: inner)
        try extrinsic.call.encode(in: inner, runtime: runtime)
        try encoder.encode(inner.output)
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>(
        unsigned decoder: ScaleDecoder
    ) throws -> Extrinsic<C, TUnsignedExtra> {
        let ext = try self.decode(decoder: decoder, call: C.self)
        guard !ext.isSigned else {
            throw ExtrinsicCodingError.badExtraType(
                expected: String(describing: TUnsignedExtra.self),
                got: String(describing: TSignedExtra.self)
            )
        }
        return Extrinsic(call: ext.call, extra: (), signed: false)
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>(
        signed decoder: ScaleDecoder
    ) throws -> Extrinsic<C, TSignedExtra> {
        let ext = try self.decode(decoder: decoder, call: C.self)
        guard ext.isSigned else {
            throw ExtrinsicCodingError.badExtraType(
                expected: String(describing: TSignedExtra.self),
                got: String(describing: TUnsignedExtra.self)
            )
        }
        let extra: TSignedExtra = try (RT.TAddress(value: ext.extra!.addr),
                                       ext.extra!.sig,
                                       ext.extra!.extra)
        return Extrinsic(call: ext.call, extra: extra, signed: true)

    }
    
    private func decode<C: Call & ScaleRuntimeDecodable>(
        decoder: ScaleDecoder,
        call: C.Type
    ) throws -> Extrinsic<
        C,
        (addr: Value<RuntimeTypeId>, sig: RC.TSignature, extra: SE.TExtra)?>
    {
        let decoder = try runtime.decoder(with: decoder.decode(Data.self))
        let version = try decoder.decode(UInt8.self)
        let isSigned = version & 0b1000_0000 > 0
        guard version == Self.version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(supported: Self.version,
                                                           got: version)
        }
        if isSigned {
            let address = try Value(from: decoder, runtime: runtime) { _ in
                try self.dynamicTypes.value.addr
            }
            let signature = try RC.TSignature(from: decoder, runtime: runtime) { _ in
                try self.dynamicTypes.value.sig
            }
            let extra = try extensions.extra(from: decoder)
            return Extrinsic(call: try C(from: decoder, runtime: runtime),
                             extra: (address, signature, extra), signed: true)
        } else {
            return Extrinsic(call: try C(from: decoder, runtime: runtime),
                             extra: nil, signed: false)
        }
    }
    
    public func setSubstrate<S: SomeSubstrate<RT>>(substrate: S) throws {
        try self.extensions.setSubstrate(substrate: substrate)
        let runtime = substrate.runtime
        self.runtime = substrate.runtime
        self.dynamicTypes = LazyProperty {
            try Self.runtimeDynamicTypes(runtime: runtime)
        }
    }
    
    private static func runtimeDynamicTypes(
        runtime: any Runtime
    ) throws -> (addr: RuntimeTypeId, sig: RuntimeTypeId) {
        var addressTypeId: RuntimeTypeId? = nil
        var sigTypeId: RuntimeTypeId? = nil
        guard runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: runtime.metadata.extrinsic.version)
        }
        for param in runtime.metadata.extrinsic.type.type.parameters {
            switch param.name {
            case "Address": addressTypeId = param.type
            case "Signature": sigTypeId = param.type
            default: continue
            }
        }
        guard let addressTypeId = addressTypeId,
              let sigTypeId = sigTypeId else {
            throw ExtrinsicCodingError.unsupportedSubstrate(
                reason: "Bad Extrinsic type. Can't obtain signature parameters"
            )
        }
        return (addressTypeId, sigTypeId)
    }
    
    public static var version: UInt8 { 4 }
}
