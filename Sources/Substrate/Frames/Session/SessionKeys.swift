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
    associatedtype TPublic: PublicKey
    
    init(pubKey: TPublic)
    var pubKey: TPublic { get }
}

public struct GrandpaSessionKey: SessionPublicKey, ScaleCodable {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
    
    public init(from decoder: ScaleDecoder) throws {
        pubKey = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(pubKey)
    }
}

public struct BabeSessionKey: SessionPublicKey, ScaleCodable {
    public typealias TSignature = Sr25519Signature
    public typealias TPublic = Sr25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
    
    public init(from decoder: ScaleDecoder) throws {
        pubKey = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(pubKey)
    }
}

public struct ImOnlineSessionKey: SessionPublicKey, ScaleCodable {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
    
    public init(from decoder: ScaleDecoder) throws {
        pubKey = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(pubKey)
    }
}

public struct AuthorityDiscoverySessionKey: SessionPublicKey, ScaleCodable {
    public typealias TSignature = Sr25519Signature
    public typealias TPublic = Sr25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
    
    public init(from decoder: ScaleDecoder) throws {
        pubKey = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(pubKey)
    }
}

public struct ParachainsSessionKey: SessionPublicKey, ScaleCodable {
    public typealias TSignature = Ed25519Signature
    public typealias TPublic = Ed25519PublicKey
    
    public let pubKey: TPublic
    public init(pubKey: TPublic) {
        self.pubKey = pubKey
    }
    
    public init(from decoder: ScaleDecoder) throws {
        pubKey = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(pubKey)
    }
}

/// Substrate base runtime keys
public struct BasicSessionKeys: SessionKeys, ScaleCodable {
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
    
    public init(from decoder: ScaleDecoder) throws {
        grandpa = try decoder.decode()
        babe = try decoder.decode()
        imOnline = try decoder.decode()
        authorityDiscovery = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder
            .encode(grandpa).encode(babe)
            .encode(imOnline).encode(authorityDiscovery)
    }
}


/// Substrate base runtime keys
public struct KusamaSessionKeys: SessionKeys, ScaleCodable {
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
    
    public init(from decoder: ScaleDecoder) throws {
        grandpa = try decoder.decode()
        babe = try decoder.decode()
        imOnline = try decoder.decode()
        parachainValidator = try decoder.decode()
        authorityDiscovery = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder
            .encode(grandpa).encode(babe).encode(imOnline)
            .encode(parachainValidator).encode(authorityDiscovery)
    }
}
