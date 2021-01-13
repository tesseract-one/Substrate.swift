//
//  ExtrinsicExtra.swift
//  
//
//  Created by Yehor Popovych on 10/13/20.
//

import Foundation
import ScaleCodec

public struct ExtrinsicExtra<Index: ScaleDynamicCodable & CompactCodable> {
    let era: ExtrinsicEra
    let nonce: Index
    let tip: BigUInt
}

extension ExtrinsicExtra: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        era = try decoder.decode()
        nonce = try decoder.decode(.compact)
        tip = try decoder.decode(.compact)
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(era).encode(nonce, .compact).encode(tip, .compact)
      }
}

extension ExtrinsicExtra: ScaleDynamicCodable {}
