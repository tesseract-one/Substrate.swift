//
//  Parachains.swift
//  
//
//  Created by Yehor Popovych on 21.05.2021.
//

import Foundation

public protocol Parachains: Session where TKeys: SessionKeysParachains {}

public protocol SessionKeysParachains: SessionKeys {
    associatedtype TParachains: SessionPublicKey
}

public struct ParachainsSessionKey: SessionPublicKey {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}
