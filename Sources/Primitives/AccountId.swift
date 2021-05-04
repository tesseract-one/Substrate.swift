//
//  AccountId.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountId<Key: PublicKey>: Equatable, Hashable {
    public let pubKey: Key
    
    public init(key: Key) {
        pubKey = key
    }
}

extension AccountId: SDefault {
    public static func `default`() -> AccountId {
        let key = try! Key(bytes: Data(repeating: 0, count: Key.bytesCount))
        return AccountId(key: key)
    }
}

extension AccountId: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        self.init(key: try decoder.decode())
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try pubKey.encode(in: encoder)
    }
}

extension AccountId: ScaleDynamicCodable {}
