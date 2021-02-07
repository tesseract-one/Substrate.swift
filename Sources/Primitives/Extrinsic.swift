//
//  Extrinsic.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec


public struct Extrinsic<Address: ScaleDynamicCodable, Call: AnyCall, Signature: ScaleDynamicCodable, Extra: SignedExtension> {
    public let signature: ExtrinsicSignature<Address, Signature, Extra>?
    public let call: Call
    
    public init(call: Call) {
        self.call = call
        self.signature = nil
    }
    
    public init(call: Call, signed: Address, signature: Signature, extra: Extra) {
        self.call = call
        self.signature = ExtrinsicSignature(sender: signed, signature: signature, extra: extra)
    }
}

extension Extrinsic: ExtrinsicProtocol {
    public typealias SignaturePayload = ExtrinsicSignature<Address, Signature, Extra>
    
    public var isSigned: Optional<Bool> { self.signature != nil }
    
    public init(call: Call, payload: Optional<SignaturePayload>) {
        if let data = payload {
            self.init(call: call, signed: data.sender, signature: data.signature, extra: data.extra)
        } else {
            self.init(call: call)
        }
    }
    
    public init(data: Data, registry: TypeRegistryProtocol) throws {
        let dec = SCALE.default.decoder(data: data)
        let info: UInt8 = try dec.decode()
        let signed = (info & 0b10000000) > 0
        let version = (info & 0b01111111)
        guard version == 4 else {
            throw SDecodingError.dataCorrupted(SDecodingError.Context(
                path: dec.path, description: "Wrong extrinsic version \(version) expected 4"
            ))
        }
        signature = signed ? try ExtrinsicSignature(from: dec, registry: registry) : nil
        let _call = try registry.decodeCall(from: dec)
        guard let call = _call as? Call else {
            throw SDecodingError.typeMismatch(
                type(of: _call),
                SDecodingError.Context(
                    path: dec.path,
                    description: "Can't cast \(type(of: _call)) to \(Call.self)"
                )
            )
        }
        self.call = call
    }
    
    public func opaque(registry: TypeRegistryProtocol) throws -> OpaqueExtrinsic {
        let encoder = SCALE.default.encoder()
        try self.encode(in: encoder, registry: registry)
        let decoder = SCALE.default.decoder(data: encoder.output)
        return try OpaqueExtrinsic(from: decoder, registry: registry)
    }
}

extension Extrinsic: ExtrinsicMetadataProtocol {
    public typealias SignedExtensions = Extra
    
    public static var VERSION: UInt8 { 4 }
}

extension Extrinsic: ScaleDynamicEncodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let data: Data = try decoder.decode()
        try self.init(data: data, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let enc = SCALE.default.encoder()
        let info = (0b01111111 & 4) + (self.signature != nil ? 0b10000000 : 0)
        try enc.encode(UInt8(info))
        if let sign = signature {
            try sign.encode(in: enc, registry: registry)
        }
        try registry.encode(call: call, in: enc)
        try encoder.encode(enc.output)
    }
}


public struct OpaqueExtrinsic: ExtrinsicProtocol, ScaleDynamicCodable {
    public typealias Call = DCall
    public typealias SignaturePayload = DNull
    
    private let registry: TypeRegistryProtocol!
    public let data: Data
    
    public var isSigned: Optional<Bool> { return nil }
    
    public init(call: Call, payload: Optional<SignaturePayload>) {
        fatalError("OpaqueExtrinsic can't be created through constructor.")
    }
    
    public init(data: Data, registry: TypeRegistryProtocol) throws {
        self.data = data
        self.registry = registry
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encoder.encode(data)
    }
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self.registry = registry
        self.data = try decoder.decode()
    }
    
    public func parse<T: ExtrinsicProtocol>(_ t: T.Type) throws -> T {
        return try t.init(data: data, registry: registry)
    }
    
    public func opaque(registry: TypeRegistryProtocol) throws -> OpaqueExtrinsic {
        self
    }
}

// TODO: Implement. Will be implemented with signing in next milestones.
//public struct ExtrinsicSignPayload {
//    public let blockHash: Hash
//    public let era: ExtrinsicEra
//    public let genesisHash: Hash
//    public let method: AnyCall
//    public let nonce: SIndex
//    public let specVersion: UInt32
//    public let transactionVersion: UInt32
//
//    public func data() -> Data {
//
//    }
//}

