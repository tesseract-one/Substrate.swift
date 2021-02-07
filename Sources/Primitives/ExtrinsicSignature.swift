//
//  ExtrinsicSignature.swift
//  
//
//  Created by Yehor Popovych on 10/13/20.
//

import Foundation
import ScaleCodec

public struct ExtrinsicSignature<Address: ScaleDynamicCodable, Signature: ScaleDynamicCodable, Extra: SignedExtension>  {
    public let sender: Address
    public let signature: Signature
    public let extra: Extra
    
    public init(sender: Address, signature: Signature, extra: Extra) {
        self.sender = sender
        self.signature = signature
        self.extra = extra
    }
}

extension ExtrinsicSignature: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        sender = try Address(from: decoder, registry: registry)
        signature = try Signature(from: decoder, registry: registry)
        extra = try Extra(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try sender.encode(in: encoder, registry: registry)
        try signature.encode(in: encoder, registry: registry)
        try extra.encode(in: encoder, registry: registry)
    }
}

