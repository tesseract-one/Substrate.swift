//
//  PublicKey.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation

public struct PublicKey: Hashable, Equatable {
    public let raw: Data
    public let type: CryptoTypeId
    
    public init(raw: Data, type: CryptoTypeId) throws {
        switch type {
        case .sr25519, .ed25519:
            guard raw.count == 32 else { throw SizeMismatchError(size: raw.count, expected: 32) }
        case .ecdsa:
            guard raw.count == 33 else { throw SizeMismatchError(size: raw.count, expected: 33) }
        }
        self.raw = raw
        self.type = type
    }
}
