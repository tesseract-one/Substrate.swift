//
//  ExtrinsicSigningPayload.swift
//  
//
//  Created by Yehor Popovych on 2/6/21.
//

import Foundation
import ScaleCodec

public struct ExtrinsicSigningPayload<Extra: SignedExtension>: ExtrinsicSigningPayloadProtocol {
    public let call: AnyCall
    public let extra: Extra
    public let payload: Extra.AdditionalSignedPayload
    
    public init(call: AnyCall, extra: Extra) throws {
        self.call = call
        self.payload = try extra.additionalSignedPayload()
        self.extra = extra
    }
}

extension ExtrinsicSigningPayload: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let enc = SCALE.default.encoder()
        try registry.encode(call: call, in: enc)
        try extra.encode(in: enc, registry: registry)
        try payload.encode(in: enc, registry: registry)
        var data = enc.output
        if (data.count > 256) {
            data = HBlake2b256.hasher.hash(data: data)
        }
        encoder.write(data)
    }
}
