//
//  AccountInfo.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountInfo<S: System> {
    let nonce: S.TIndex
    let refCount: UInt32
    let data: S.TAccountData
}

extension AccountInfo: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        nonce = try S.TIndex(from: decoder, registry: registry)
        refCount = try decoder.decode()
        data = try S.TAccountData(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try nonce.encode(in: encoder, registry: registry)
        try encoder.encode(refCount)
        try data.encode(in: encoder, registry: registry)
    }
}
