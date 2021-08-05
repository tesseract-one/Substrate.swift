//
//  Extrinsic.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec

public struct Extrinsic<Addr: Address, Sign: Signature, Extra: SignedExtension> {
    public let signature: ExtrinsicSignature<Addr, Sign, Extra>?
    public let call: AnyCall
}

extension Extrinsic: ExtrinsicProtocol {
    public typealias SigningPayload = ExtrinsicSigningPayload<Extra>
    public typealias SignaturePayload = ExtrinsicSignature<Addr, Sign, Extra>
    
    public var isSigned: Bool { self.signature != nil }
    
    public init(call: AnyCall, signature: Optional<SignaturePayload> = nil) {
        self.call = call
        self.signature = signature
    }
    
    public init(payload: SigningPayload) {
        self.call = payload.call
        self.signature = nil
    }
    
    public func payload(with extra: Extra) throws -> SigningPayload {
        try SigningPayload(call: call, extra: extra)
    }
    
    public func signed(by address: Addr,
                       with signature: Sign,
                       payload: ExtrinsicSigningPayload<Extra>) throws -> Self {
        let signature = SignaturePayload(sender: address,
                                         signature: signature,
                                         extra: payload.extra)
        return Self(call: call, signature: signature)
    }
    
    public static var VERSION: UInt8 { 4 }
}

extension Extrinsic: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let info: UInt8 = try decoder.decode()
        let signed = (info & 0b10000000) > 0
        let version = (info & 0b01111111)
        guard version == Self.VERSION else {
            throw SDecodingError.dataCorrupted(SDecodingError.Context(
                path: decoder.path, description: "Wrong extrinsic version \(version) expected \(Self.VERSION)"
            ))
        }
        signature = signed ? try ExtrinsicSignature(from: decoder, registry: registry) : nil
        call = try registry.decode(callFrom: decoder)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let info = (0b01111111 & self.version) + (self.signature != nil ? 0b10000000 : 0)
        try encoder.encode(UInt8(info))
        if let sign = signature {
            try sign.encode(in: encoder, registry: registry)
        }
        try registry.encode(call: call, in: encoder)
    }
}
