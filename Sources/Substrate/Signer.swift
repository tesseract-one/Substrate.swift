//
//  Signer.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation

public protocol Signer {
    func getAccount() async throws -> Data
    func sign(tx: Data) async throws -> Data
}
