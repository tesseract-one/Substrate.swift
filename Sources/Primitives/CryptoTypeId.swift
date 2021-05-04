//
//  CryptoTypeId.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//

import Foundation

public struct CryptoTypeId: Equatable, Hashable {
    public let id: UInt32
    
    public init(id: UInt32) {
        self.id = id
    }
    
    public static let ed25519 = CryptoTypeId(id: 0x65643235) // "ed25"
    public static let ecdsa = CryptoTypeId(id: 0x65636473) // "ecds"
    public static let sr25519 = CryptoTypeId(id: 0x73723235) // "sr25"
}

extension CryptoTypeId: RawRepresentable {
    public typealias RawValue = UInt32
    
    public init?(rawValue: Self.RawValue) {
        self.init(id: rawValue)
    }
    
    public var rawValue: Self.RawValue { id }
}

public enum CryptoTypeError: Error {
    case uknownType(id: UInt32)
    case wrongType(type: CryptoTypeId, expected: [CryptoTypeId])
}
