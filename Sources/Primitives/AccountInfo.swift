//
//  AccountInfo.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountInfo {
    let nonce: UInt32
    let refCount: UInt32
    let data: AccountData
}

extension AccountInfo: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        nonce = try decoder.decode()
        refCount = try decoder.decode()
        data = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(nonce).encode(refCount).encode(data)
    }
}

extension AccountInfo: ScaleDynamicCodable {}
