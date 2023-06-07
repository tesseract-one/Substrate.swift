//
//  CryptoTypeId.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//

import Foundation

public enum CryptoTypeId: String, Hashable, Equatable {
    case ed25519 = "ed25"
    case sr25519 = "sr25"
    case ecdsa = "ecds"
}

public enum CryptoError: Error {
    case unsupported(type: CryptoTypeId, supports: [CryptoTypeId])
}
