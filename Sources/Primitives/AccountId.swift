//
//  AccountId.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountId: Equatable, Hashable {
    public let pubKey: Data
    
    public init(key: Data) {
        precondition(
            key.count == AccountId.fixedBytesCount,
            "Wrong data length: \(key.count) expected \(Self.fixedBytesCount)"
        )
        pubKey = key
    }
}

extension AccountId: SDefault {
    public static func `default`() -> AccountId {
        AccountId(key: Data(repeating: 0, count: Self.fixedBytesCount))
    }
}

extension AccountId: ScaleFixedData {
    public init(decoding data: Data) throws {
        pubKey = data
    }
    
    public func encode() throws -> Data {
        return self.pubKey
    }
    
    public static var fixedBytesCount: Int = 32
}

extension AccountId: ScaleDynamicCodable {}
