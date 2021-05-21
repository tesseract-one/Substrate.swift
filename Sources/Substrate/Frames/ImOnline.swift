//
//  ImOnline.swift
//  
//
//  Created by Yehor Popovych on 21.05.2021.
//

import Foundation

public protocol ImOnline: Session where TKeys: SessionKeysImOnline {}

public protocol SessionKeysImOnline: SessionKeys {
    associatedtype TImOnline: SessionPublicKey
}

public struct ImOnlineSessionKey: SessionPublicKey {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

open class ImOnlineModule<I: ImOnline>: ModuleProtocol {
    public typealias Frame = I
    
    public static var NAME: String { "ImOnline" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
    }
}
