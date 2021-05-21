//
//  Babe.swift
//  
//
//  Created by Yehor Popovych on 21.05.2021.
//

import Foundation

public protocol Babe: Session where TKeys: SessionKeysBabe {}

public protocol SessionKeysBabe: SessionKeys {
    associatedtype TBabe: SessionPublicKey
}

public struct BabeSessionKey: SessionPublicKey {
    public typealias TSignature = Sr25519Signature
    public typealias TPublic = Sr25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

open class BabeModule<B: Babe>: ModuleProtocol {
    public typealias Frame = B
    
    public static var NAME: String { "Babe" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
    }
}
