//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 10/11/20.
//

import Foundation
import ScaleCodec

public typealias SSignature = MultiSignature

public enum MultiSignature {
    case ed25519(Hash512)
    case sr25519(Hash512)
    case ecdsa(Data) // 65 bytes
}

extension MultiSignature: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .ed25519(decoder.decode())
        case 1: self = try .sr25519(decoder.decode())
        case 2: self = try .ecdsa(decoder.decode(.fixed(65)))
        default: throw decoder.enumCaseError(for: opt)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .ed25519(let s): try encoder.encode(0, .enumCaseId).encode(s)
        case .sr25519(let s): try encoder.encode(1, .enumCaseId).encode(s)
        case .ecdsa(let s): try encoder.encode(2, .enumCaseId).encode(s, .fixed(65))
        }
    }
}

extension MultiSignature: ScaleDynamicCodable {}
