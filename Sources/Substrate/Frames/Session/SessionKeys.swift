//
//  SessionKeys.swift
//  
//
//  Created by Yehor Popovych on 05.05.2021.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public protocol SessionKeys: ScaleDynamicCodable {}

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

/// Substrate base runtime keys
public struct BasicSessionKeys:
    SessionKeys, SessionKeysBabe, SessionKeysGrandpa,
    SessionKeysImOnline, SessionKeysAuthorityDiscovery,
    SessionKeysParachains
{
    public typealias TBabe = BabeSessionKey
    public typealias TGrandpa = GrandpaSessionKey
    public typealias TImOnline = ImOnlineSessionKey
    public typealias TAuthorityDiscovery = AuthorityDiscoverySessionKey
    public typealias TParachains = ParachainsSessionKey
    
    /// GRANDPA session key
    public let grandpa: TGrandpa
    /// BABE session key
    public let babe: TBabe
    /// ImOnline session key
    public let imOnline: TImOnline
    /// Parachain validation session key
    public let parachains: TParachains
    /// AuthorityDiscovery session key
    public let authorityDiscovery: TAuthorityDiscovery
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        grandpa = try TGrandpa(from: decoder, registry: registry)
        babe = try TBabe(from: decoder, registry: registry)
        imOnline = try TImOnline(from: decoder, registry: registry)
        parachains = try TParachains(from: decoder, registry: registry)
        authorityDiscovery = try TAuthorityDiscovery(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try grandpa.encode(in: encoder, registry: registry)
        try babe.encode(in: encoder, registry: registry)
        try imOnline.encode(in: encoder, registry: registry)
        try parachains.encode(in: encoder, registry: registry)
        try authorityDiscovery.encode(in: encoder, registry: registry)
    }
}


/// Substrate base runtime keys
public struct KusamaSessionKeys:
    SessionKeys, SessionKeysBabe, SessionKeysGrandpa,
    SessionKeysImOnline, SessionKeysAuthorityDiscovery,
    SessionKeysParachains
{
    public typealias TBabe = BabeSessionKey
    public typealias TGrandpa = GrandpaSessionKey
    public typealias TImOnline = ImOnlineSessionKey
    public typealias TAuthorityDiscovery = AuthorityDiscoverySessionKey
    public typealias TParachains = ParachainsSessionKey
    
    /// GRANDPA session key
    public let grandpa: TGrandpa
    /// BABE session key
    public let babe: TBabe
    /// ImOnline session key
    public let imOnline: TImOnline
    /// Parachain validation session key
    public let parachainValidator: TParachains
    /// AuthorityDiscovery session key
    public let authorityDiscovery: TAuthorityDiscovery
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        grandpa = try TGrandpa(from: decoder, registry: registry)
        babe = try TBabe(from: decoder, registry: registry)
        imOnline = try TImOnline(from: decoder, registry: registry)
        parachainValidator = try TParachains(from: decoder, registry: registry)
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
