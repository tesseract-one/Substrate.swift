//
//  AuthorityDiscovery.swift
//  
//
//  Created by Yehor Popovych on 21.05.2021.
//

import Foundation

public protocol AuthorityDiscovery: Session where TKeys: SessionKeysAuthorityDiscovery {}

public protocol SessionKeysAuthorityDiscovery: SessionKeys {
    associatedtype TAuthorityDiscovery: SessionPublicKey
}

public struct AuthorityDiscoverySessionKey: SessionPublicKey {
    public typealias TSignature = Sr25519Signature
    public typealias TPublic = Sr25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

open class AuthorityDiscoveryModule<I: AuthorityDiscovery>: ModuleProtocol {
    public typealias Frame = I
    
    public static var NAME: String { "AuthorityDiscovery" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
    }
}
