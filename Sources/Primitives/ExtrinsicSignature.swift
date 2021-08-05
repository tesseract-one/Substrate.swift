//
//  ExtrinsicSignature.swift
//  
//
//  Created by Yehor Popovych on 10/13/20.
//

import Foundation
import ScaleCodec

public struct ExtrinsicSignature<Addr: Address, Sign: Signature, Extra: SignedExtension>: ExtrinsicSignatureProtocol  {
    public typealias AddressType = Addr
    public typealias SignatureType = Sign
    
    public let sender: Addr
    public let signature: Sign
    public let extra: Extra
    
    public init(sender: Addr, signature: Sign, extra: Extra) {
        self.sender = sender
        self.signature = signature
        self.extra = extra
    }
}

extension ExtrinsicSignature: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        sender = try Addr(from: decoder, registry: registry)
        signature = try Sign(from: decoder, registry: registry)
        extra = try Extra(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try sender.encode(in: encoder, registry: registry)
        try signature.encode(in: encoder, registry: registry)
        try extra.encode(in: encoder, registry: registry)
    }
}

