//
//  Grandpa.swift
//  
//
//  Created by Yehor Popovych on 21.05.2021.
//

import Foundation

public protocol Grandpa: Session where TKeys: SessionKeysGrandpa {}

public protocol SessionKeysGrandpa: SessionKeys {
    associatedtype TGrandpa: SessionPublicKey
}

public struct GrandpaSessionKey: SessionPublicKey {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

open class GrandpaModule<G: Grandpa>: ModuleProtocol {
    public typealias Frame = G
    
    public static var NAME: String { "Grandpa" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
    }
}
