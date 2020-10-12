//
//  Extrinsic.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec

public struct Extrinsic<Call: AnyCall> {
    public let signature: ExtrinsicSignature?
    public let call: Call
}

extension Extrinsic: ScaleRegistryEncodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        let data: Data = try decoder.decode()
        let dec = SCALE.default.decoder(data: data)
        let info: UInt8 = try dec.decode()
        let signed = (info & 0b10000000) > 0
        let version = (info & 0b01111111)
        guard version == 4 else {
            throw SDecodingError.dataCorrupted(SDecodingError.Context(
                path: decoder.path, description: "Wrong extrinsic version \(version) expected 4"
            ))
        }
        signature = signed ? try dec.decode(ExtrinsicSignature.self) : nil
        let _call = try registry.decodeCall(from: dec)
        guard let call = _call as? Call else {
            throw SDecodingError.typeMismatch(
                type(of: _call),
                SDecodingError.Context(
                    path: decoder.path,
                    description: "Can't cast \(type(of: _call)) to \(Call.self)"
                )
            )
        }
        self.call = call
    }
    
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        let enc = SCALE.default.encoder()
        let info = (0b01111111 & 4) + (self.signature != nil ? 0b10000000 : 0)
        try enc.encode(UInt8(info))
        if let sign = signature {
            try enc.encode(sign)
        }
        try registry.encode(call: call, in: enc)
        try encoder.encode(enc.output)
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

