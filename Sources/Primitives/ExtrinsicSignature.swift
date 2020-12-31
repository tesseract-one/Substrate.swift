//
//  ExtrinsicSignature.swift
//  
//
//  Created by Yehor Popovych on 10/13/20.
//

import Foundation
import ScaleCodec

public struct ExtrinsicSignature {
    public let sender: Address
    public let signature: SSignature
    public let extra: ExtrinsicExtra
}

extension ExtrinsicSignature: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        sender = try decoder.decode()
        signature = try decoder.decode()
        extra = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(sender).encode(signature).encode(extra)
    }
}

extension ExtrinsicSignature: ScaleDynamicCodable {}
