//
//  SessionKeys.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public protocol SessionKeys: ScaleDynamicCodable {
    associatedtype TBabe: SessionPublicKey
    associatedtype TGrandpa: SessionPublicKey
    associatedtype TImOnline: SessionPublicKey
    associatedtype TAuthorityDiscovery: SessionPublicKey
}

public protocol SessionPublicKey: ScaleDynamicCodable {
    associatedtype TSignature: Signature
    associatedtype TPublic: PublicKey & Hashable
    
    init(pubKey: TPublic)
    var pubKey: TPublic { get }
}

extension SessionPublicKey {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(pubKey: TPublic(from: decoder, registry: registry))
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try pubKey.encode(in: encoder, registry: registry)
    }
}

public struct GrandpaSessionKey: SessionPublicKey {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

public struct BabeSessionKey: SessionPublicKey {
    public typealias TSignature = Sr25519Signature
    public typealias TPublic = Sr25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

public struct ImOnlineSessionKey: SessionPublicKey {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

public struct AuthorityDiscoverySessionKey: SessionPublicKey {
    public typealias TSignature = Sr25519Signature
    public typealias TPublic = Sr25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

public struct ParachainsSessionKey: SessionPublicKey {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
}

/// Substrate base runtime keys
public struct BasicSessionKeys: SessionKeys {
    public typealias TBabe = BabeSessionKey
    public typealias TGrandpa = GrandpaSessionKey
    public typealias TImOnline = ImOnlineSessionKey
    public typealias TAuthorityDiscovery = AuthorityDiscoverySessionKey
    
    /// GRANDPA session key
    public let grandpa: TGrandpa
    /// BABE session key
    public let babe: TBabe
    /// ImOnline session key
    public let imOnline: TImOnline
    /// AuthorityDiscovery session key
    public let authorityDiscovery: TAuthorityDiscovery
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        grandpa = try TGrandpa(from: decoder, registry: registry)
        babe = try TBabe(from: decoder, registry: registry)
        imOnline = try TImOnline(from: decoder, registry: registry)
        authorityDiscovery = try TAuthorityDiscovery(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try grandpa.encode(in: encoder, registry: registry)
        try babe.encode(in: encoder, registry: registry)
        try imOnline.encode(in: encoder, registry: registry)
        try authorityDiscovery.encode(in: encoder, registry: registry)
    }
}


/// Substrate base runtime keys
public struct KusamaSessionKeys: SessionKeys {
    public typealias TBabe = BabeSessionKey
    public typealias TGrandpa = GrandpaSessionKey
    public typealias TImOnline = ImOnlineSessionKey
    public typealias TAuthorityDiscovery = AuthorityDiscoverySessionKey
    
    /// GRANDPA session key
    public let grandpa: TGrandpa
    /// BABE session key
    public let babe: TBabe
    /// ImOnline session key
    public let imOnline: TImOnline
    /// Parachain validation session key
    public let parachainValidator: ParachainsSessionKey
    /// AuthorityDiscovery session key
    public let authorityDiscovery: TAuthorityDiscovery
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        grandpa = try TGrandpa(from: decoder, registry: registry)
        babe = try TBabe(from: decoder, registry: registry)
        imOnline = try TImOnline(from: decoder, registry: registry)
        parachainValidator = try ParachainsSessionKey(from: decoder, registry: registry)
        authorityDiscovery = try TAuthorityDiscovery(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try grandpa.encode(in: encoder, registry: registry)
        try babe.encode(in: encoder, registry: registry)
        try imOnline.encode(in: encoder, registry: registry)
        try parachainValidator.encode(in: encoder, registry: registry)
        try authorityDiscovery.encode(in: encoder, registry: registry)
    }
}
