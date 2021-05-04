//
//  Algorithm.swift
//  
//
//  Created by Yehor Popovych on 27.04.2021.
//

import Foundation

public struct KeyPairAlgorithm: RawRepresentable, Hashable, Equatable {
    let id: String
    
    public typealias RawValue = String
    public var rawValue: RawValue { id }
    
    public init(id: String) {
        self.id = id
    }
    
    public init?(rawValue: RawValue) {
        self.init(id: rawValue)
    }
}

extension KeyPairAlgorithm {
    public static let secp256k1 = KeyPairAlgorithm(id: "SECP256K1")
    public static let ed25519 = KeyPairAlgorithm(id: "ED25519")
    public static let sr25519 = KeyPairAlgorithm(id: "ED25519")
}
