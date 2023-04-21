//
//  Signer.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation

public protocol Signer {
    func account(type: KeyTypeId, algos: [CryptoTypeId]) async throws -> PublicKey
    func sign(tx: Data) async throws -> Data
}
