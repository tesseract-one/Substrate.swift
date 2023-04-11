//
//  ExtrinsicV4.swift
//  
//
//  Created by Yehor Popovych on 13.01.2023.
//

import Foundation
import ScaleCodec

public class DynamicExtrinsicManagerV4<S: System>: ExtrinsicManager {
    public typealias RT = S
    public typealias TUnsignedParams = Void
    public typealias TSigningParams = [DynamicExtrinsicExtensionKey: Value<Void>]
    public typealias TUnsignedExtra = Void
    public typealias TSigningExtra = (extra: Value<Void>, additional: Value<Void>)
    public typealias TSignedExtra = (address: RT.TAddress, signature: RT.TSignature, extra: Value<Void>)
    
    private let extensions: [String: DynamicExtrinsicExtension]
    private var substrate: (any DynamicExtrinsicManagerSubstrateWrapper)!
    
    public init(extensions: [DynamicExtrinsicExtension]) {
        self.substrate = nil
        self.extensions = Dictionary(uniqueKeysWithValues: extensions.map { ($0.identifier, $0) })
    }
    
    public func build<C: Call>(
        unsigned call: C, params: TUnsignedParams
    ) async throws -> Extrinsic<C, TUnsignedExtra> {
        Extrinsic(call: call, extra: (), signed: false)
    }
    
    public func encode<C: Call>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>, in encoder: ScaleEncoder) throws {
        let inner = substrate.runtime.encoder()
        try inner.encode(Self.version & 0b0111_1111)
        try extrinsic.call.encode(in: inner, runtime: substrate.runtime)
        try encoder.encode(inner.output)
    }
    
    public func build<C: Call>(
        payload extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: TSigningParams
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra> {
        return try await ExtrinsicSignPayload(call: extrinsic.call,
                                              extra: (substrate.extra(params: params),
                                                      substrate.additionalSigned(params: params)))
    }
    
    public func encode<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>, in encoder: ScaleEncoder) throws {
        try payload.call.encode(in: encoder, runtime: substrate.runtime)
        try payload.extra.extra.encode(in: encoder, as: substrate.extraType, runtime: substrate.runtime)
        guard let additionals = payload.extra.additional.sequence else {
            throw ExtrinsicCodingError.badExtraType(expected: "Value<Void>.sequence",
                                                    got: String(describing: payload.extra.additional))
        }
        guard additionals.count == substrate.extrinsic.extensions.count else {
            throw ExtrinsicCodingError.badExtrasCount(expected: substrate.extrinsic.extensions.count,
                                                      got: additionals.count)
        }
        for (addl, info) in zip(additionals, substrate.extrinsic.extensions) {
            try addl.encode(in: encoder, as: info.additionalSigned.id, runtime: substrate.runtime)
        }
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>(
        payload decoder: ScaleDecoder
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra> {
        let call = try C(from: decoder, runtime: substrate.runtime)
        let extra = try substrate.runtime
                .decode(from: decoder, type: substrate.extraType)
                .removingContext()
        let additional = try substrate.extrinsic.extensions.map { info in
            try substrate.runtime
                .decode(from: decoder, type: info.additionalSigned.id)
                .removingContext()
        }
        return ExtrinsicSignPayload(call: call, extra: (extra, .sequence(additional)))
    }
    
    public func build<C: Call>(signed payload: ExtrinsicSignPayload<C, TSigningExtra>,
                               address: RT.TAddress,
                               signature: RT.TSignature) throws -> Extrinsic<C, TSignedExtra> {
        Extrinsic(call: payload.call, extra: (address, signature, payload.extra.extra), signed: true)
    }
    
    public func encode<C: Call>(signed extrinsic: Extrinsic<C, TSignedExtra>, in encoder: ScaleEncoder) throws {
        let inner = substrate.runtime.encoder()
        try inner.encode(Self.version | 0b1000_0000)
        try extrinsic.extra.address.asValue().encode(in: inner,
                                                     as: substrate.addressType,
                                                     runtime: substrate.runtime)
        try extrinsic.extra.signature.asValue().encode(in: inner,
                                                       as: substrate.signatureType,
                                                       runtime: substrate.runtime)
        try extrinsic.extra.extra.encode(in: inner,
                                         as: substrate.extraType,
                                         runtime: substrate.runtime)
        try extrinsic.call.encode(in: inner, runtime: substrate.runtime)
        try encoder.encode(inner.output)
    }
    
    public func decode(dynamic decoder: ScaleDecoder) throws -> Extrinsic<DynamicCall<RuntimeTypeId>, Value<RuntimeTypeId>> {
        let ext = try self.decode(decoder: decoder, call: DynamicCall<RuntimeTypeId>.self)
        let extra: Value<RuntimeTypeId>
        if ext.isSigned {
            extra = Value(value: .sequence([ext.extra!.addr, ext.extra!.sig, ext.extra!.extra]),
                          context: substrate.extrinsic.type.id)
        } else {
            extra = Value(value: .sequence([]),
                          context: substrate.extrinsic.type.id)
        }
        return Extrinsic(call: ext.call, extra: extra, signed: ext.isSigned)
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable, E>(
        static decoder: ScaleDecoder
    ) throws -> Extrinsic<C, E> {
        let ext = try self.decode(decoder: decoder, call: C.self)
        if ext.isSigned && E.self != TSignedExtra.self {
            throw ExtrinsicCodingError.badExtraType(
                expected: String(describing: TSignedExtra.self),
                got: String(describing: E.self)
            )
        }
        if !ext.isSigned && E.self != TUnsignedExtra.self {
            throw ExtrinsicCodingError.badExtraType(
                expected: String(describing: TUnsignedExtra.self),
                got: String(describing: E.self)
            )
        }
        if ext.isSigned {
            let extra: TSignedExtra = try (RT.TAddress(value: ext.extra!.addr),
                                           RT.TSignature(value: ext.extra!.sig),
                                           ext.extra!.extra.removingContext())
            return Extrinsic(call: ext.call, extra: extra as! E, signed: true)
        } else {
            return Extrinsic(call: ext.call, extra: () as! E, signed: false)
        }
    }
    
    private func decode<C: Call & ScaleRuntimeDecodable>(
        decoder: ScaleDecoder,
        call: C.Type
    ) throws -> Extrinsic<
        C,
        (addr: Value<RuntimeTypeId>, sig: Value<RuntimeTypeId>, extra: Value<RuntimeTypeId>)?>
    {
        let decoder = try substrate.runtime.decoder(with: decoder.decode(Data.self))
        let version = try decoder.decode(UInt8.self)
        let isSigned = version & 0b1000_0000 > 0
        guard version == Self.version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(supported: Self.version,
                                                           got: version)
        }
        if isSigned {
            let address = try substrate.runtime.decode(from: decoder, type: substrate.addressType)
            let signature = try substrate.runtime.decode(from: decoder, type: substrate.signatureType)
            let extra = try substrate.runtime.decode(from: decoder, type: substrate.extraType)
            return Extrinsic(call: try C(from: decoder, runtime: substrate.runtime),
                             extra: (address, signature, extra), signed: true)
        } else {
            return Extrinsic(call: try C(from: decoder, runtime: substrate.runtime),
                             extra: nil, signed: false)
        }
    }
    
    public func setSubstrate<S: AnySubstrate<RT>>(substrate: S) throws {
        self.substrate = try DynamicSubstrateWrapper(substrate: substrate,
                                                     version: Self.version,
                                                     extensions: extensions)
    }
    
    public static var version: UInt8 { 4 }
}

private protocol DynamicExtrinsicManagerSubstrateWrapper {
    var runtime: any Runtime { get }
    var extrinsic: ExtrinsicMetadata { get }
    var addressType: RuntimeTypeId { get }
    var signatureType: RuntimeTypeId { get }
    var extraType: RuntimeTypeId { get }
    
    func extra(params: [DynamicExtrinsicExtensionKey: Value<Void>]) async throws -> Value<Void>
    func additionalSigned(params: [DynamicExtrinsicExtensionKey: Value<Void>]) async throws -> Value<Void>
}

private struct DynamicSubstrateWrapper<ST: AnySubstrate>: DynamicExtrinsicManagerSubstrateWrapper {
    weak var substrate: ST!
    let extensions: [DynamicExtrinsicExtension]
    
    let addressType: RuntimeTypeId
    let signatureType: RuntimeTypeId
    let extraType: RuntimeTypeId
    
    init(substrate: ST, version: UInt8, extensions: [String: DynamicExtrinsicExtension]) throws {
        var extraTypeId: RuntimeTypeId? = nil
        var addressTypeId: RuntimeTypeId? = nil
        var sigTypeId: RuntimeTypeId? = nil
        guard substrate.runtime.metadata.extrinsic.version == version else {
            throw ExtrinsicCodingError.badExtrinsicVersion(
                supported: version,
                got: substrate.runtime.metadata.extrinsic.version)
        }
        for param in substrate.runtime.metadata.extrinsic.type.type.parameters {
            switch param.name {
            case "Address": addressTypeId = param.type
            case "Signature": sigTypeId = param.type
            case "Extra": extraTypeId = param.type
            default: continue
            }
        }
        guard let extraTypeId = extraTypeId,
              let addressTypeId = addressTypeId,
              let sigTypeId = sigTypeId else {
            throw ExtrinsicCodingError.unsupportedSubstrate(
                reason: "Bad Extrinsic type. Can't obtain signature parameters"
            )
        }
        self.extensions = try substrate.runtime.metadata.extrinsic.extensions.map { info in
            guard let ext = extensions[info.identifier] else {
                throw  ExtrinsicCodingError.unknownExtension(identifier: info.identifier)
            }
            return ext
        }
        self.addressType = addressTypeId
        self.signatureType = sigTypeId
        self.extraType = extraTypeId
        self.substrate = substrate
    }
    
    @inlinable
    var runtime: any Runtime { substrate.runtime }
    
    @inlinable
    var extrinsic: ExtrinsicMetadata { substrate.runtime.metadata.extrinsic }
    
    func extra(params: [DynamicExtrinsicExtensionKey: Value<Void>]) async throws -> Value<Void> {
        var extra: [Value<Void>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.extra(substrate: substrate!, params: params))
        }
        return .sequence(extra)
    }
    
    func additionalSigned(params: [DynamicExtrinsicExtensionKey: Value<Void>]) async throws -> Value<Void> {
        var extra: [Value<Void>] = []
        extra.reserveCapacity(extensions.count)
        for ext in extensions {
            try await extra.append(ext.additionalSigned(substrate: substrate!, params: params))
        }
        return .sequence(extra)
    }
}
