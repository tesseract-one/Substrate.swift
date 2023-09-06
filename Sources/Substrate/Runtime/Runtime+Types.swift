//
//  Runtime+Types.swift
//  
//
//  Created by Yehor Popovych on 07/07/2023.
//

import Foundation
import ScaleCodec

public extension NetworkType {
    typealias LazyId = (Runtime) throws -> Id
    
    struct IdNeverCalledError: Error, CustomStringConvertible {
        public var description: String { "Asked for IdNever" }
        public init() {}
    }
    
    static func IdNever(_ r: Runtime) throws -> NetworkType.Id { throw IdNeverCalledError() }
}

public extension Runtime {
    @inlinable
    func create<A: AccountId>(account: A.Type, pub: any PublicKey) throws -> A {
        try A(pub: pub, runtime: self) { try $0.types.account.get().id }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, raw: Data) throws -> A {
        try A(raw: raw, runtime: self) { try $0.types.account.get().id }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, from string: String) throws -> A {
        try A(from: string, runtime: self) { try $0.types.account.get().id }
    }
    
    @inlinable
    func create<A: Address>(address: A.Type, account: A.TAccountId) throws -> A {
        try A(accountId: account, runtime: self) { try $0.types.account.get().id }
    }
    
    @inlinable
    func create<H: Hash>(hash: H.Type, raw: Data) throws -> H {
        try H(raw: raw, runtime: self) { try $0.types.hash.get().id }
    }
    
    @inlinable
    func create<S: Signature>(signature: S.Type, raw: Data, algorithm: CryptoTypeId) throws -> S {
        try S(raw: raw, algorithm: algorithm, runtime: self) { $0.types.signature.id }
    }
    
    @inlinable
    func create<S: Signature>(fakeSignature: S.Type, algorithm: CryptoTypeId) throws -> S {
        try S(fake: algorithm, runtime: self) { $0.types.signature.id }
    }
    
    @inlinable
    func algorithms<S: Signature>(signature: S.Type) throws -> [CryptoTypeId] {
        try S.algorithms(runtime: self) { $0.types.signature.id }
    }
    
    @inlinable
    func decode<A: AccountId, D: ScaleCodec.Decoder>(
        account: A.Type, from decoder: inout D
    ) throws -> A {
        try decode(from: &decoder) { try $0.types.account.get().id }
    }
    
    @inlinable
    func encode<A: AccountId, E: ScaleCodec.Encoder>(
        account: A, in encoder: inout E
    ) throws {
        try encode(value: account, in: &encoder) { try $0.types.account.get().id }
    }
    
    @inlinable
    func decode<A: Address, D: ScaleCodec.Decoder>(
        address: A.Type, from decoder: inout D
    ) throws -> A {
        try decode(from: &decoder) { $0.types.address.id }
    }
    
    @inlinable
    func encode<A: Address, E: ScaleCodec.Encoder>(
        address: A, in encoder: inout E
    ) throws {
        try encode(value: address, in: &encoder) { $0.types.address.id }
    }
    
    @inlinable
    func decode<S: Signature, D: ScaleCodec.Decoder>(
        signature: S.Type, from decoder: inout D
    ) throws -> S {
        try decode(from: &decoder) { $0.types.signature.id }
    }
    
    @inlinable
    func encode<S: Signature, E: ScaleCodec.Encoder>(
        signature: S, in encoder: inout E
    ) throws {
        try encode(value: signature, in: &encoder) { $0.types.signature.id }
    }
    
    @inlinable
    func decode<C: Call & RuntimeDecodable, D: ScaleCodec.Decoder>(
        call: C.Type, from decoder: inout D
    ) throws -> C {
        try decode(from: &decoder)
    }
    
    @inlinable
    func encode<C: Call, E: ScaleCodec.Encoder>(
        call: C, in encoder: inout E
    ) throws {
        try encode(value: call, in: &encoder)
    }
    
    @inlinable
    func hash<H: Hash>(type: H.Type, data: Data) throws -> H {
        try create(hash: type, raw: hasher.hash(data: data))
    }
    
    @inlinable
    func decode<C: Call & RuntimeDecodable, D: ScaleCodec.Decoder, Extra: ExtrinsicExtra>(
        extrinsic: Extrinsic<C, Extra>.Type, from decoder: inout D
    ) throws -> Extrinsic<C, Extra> {
        try extrinsicDecoder.extrinsic(from: &decoder, runtime: self)
    }
}

public extension NetworkType {
    @inlinable
    func asPrimitive(_ runtime: any Runtime) -> NetworkType.Primitive? {
        asPrimitive(runtime.metadata)
    }
    
    @inlinable
    func asBytes(_ runtime: any Runtime) -> UInt32? {
        asBytes(runtime.metadata)
    }
    
    @inlinable
    func isEmpty(_ runtime: any Runtime) -> Bool {
        isEmpty(runtime.metadata)
    }
    
    @inlinable
    func asOptional(_ runtime: any Runtime) -> NetworkType.Field? {
        asOptional(runtime.metadata)
    }
    
    @inlinable
    func asCompact(_ runtime: any Runtime) -> Self? {
        asCompact(runtime.metadata)
    }
    
    @inlinable
    func isBitSequence(_ runtime: any Runtime) -> Bool {
        isBitSequence(runtime.metadata)
    }
    
    @inlinable
    func asResult(_ runtime: any Runtime) -> (ok: NetworkType.Field, err: NetworkType.Field)? {
        asResult(runtime.metadata)
    }
    
    func flatten(_ runtime: any Runtime) -> Self {
        flatten(runtime.metadata)
    }
}

public protocol RuntimeValidatableType {
    func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
}
