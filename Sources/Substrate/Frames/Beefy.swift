//
//  Beefy.swift
//  
//
//  Created by Yehor Popovych on 21.05.2021.
//

import Foundation

public protocol BeefyApi: Grandpa {
    associatedtype TBeefyPayload: Hash
    associatedtype TBeefyValidatorSetId: ScaleDynamicCodable
    associatedtype TBeefySignature: Signature
}

public protocol Beefy: BeefyApi where TKeys: SessionKeysBeefy {}

public protocol SessionKeysBeefy: SessionKeys {
    associatedtype TBeefy: SessionPublicKey
}

public struct BeefySessionKey: SessionPublicKey {
    public typealias TSignature = EcdsaSignature
    public typealias TPublic = EcdsaPublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

open class BeefyModule<B: Beefy>: ModuleProtocol {
    public typealias Frame = B
    
    public static var NAME: String { "Beefy" }
    
    public init() {}
    
    open func registerEventsCallsAndTypes<R>(in registry: R) throws where R : TypeRegistryProtocol {
        
    }
}

public struct BeefyAuthoritiesStorageKey<B: Beefy> {
    public init() {}
}

extension BeefyAuthoritiesStorageKey: PlainStorageKey {
    public typealias Value = Array<B.TKeys.TBeefy.TPublic>
    public typealias Module = BeefyModule<B>
    
    public static var FIELD: String { "Authorities" }
}

public struct BeefyValidatorSetIdStorageKey<B: Beefy> {
    public init() {}
}

extension BeefyValidatorSetIdStorageKey: PlainStorageKey {
    public typealias Value = B.TBeefyValidatorSetId
    public typealias Module = BeefyModule<B>
    
    public static var FIELD: String { "ValidatorSetId" }
}

public struct BeefyNextAuthoritiesStorageKey<B: Beefy> {
    public init() {}
}

extension BeefyNextAuthoritiesStorageKey: PlainStorageKey {
    public typealias Value = Array<B.TKeys.TBeefy.TPublic>
    public typealias Module = BeefyModule<B>
    
    public static var FIELD: String { "NextAuthorities" }
}

