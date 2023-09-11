//
//  Runtime+Types.swift
//  
//
//  Created by Yehor Popovych on 07/07/2023.
//

import Foundation
import ScaleCodec

public extension TypeDefinition {
    typealias Lazy = () throws -> TypeDefinition
    
    struct NeverCalledError: Error, CustomDebugStringConvertible {
        public var debugDescription: String { "Asked for Never TypeDef" }
        public init() {}
    }
    
    @inlinable
    static func Never() throws -> TypeDefinition { throw NeverCalledError() }
}

public extension Runtime {
    @inlinable
    func create<A: AccountId>(account: A.Type, pub: any PublicKey) throws -> A {
        try A(pub: pub, runtime: self) { try types.account.get() }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, raw: Data) throws -> A {
        try A(raw: raw, runtime: self) { try types.account.get() }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, from string: String) throws -> A {
        try A(from: string, runtime: self) { try types.account.get() }
    }
    
    @inlinable
    func create<A: Address>(address: A.Type, account: A.TAccountId) throws -> A {
        try A(accountId: account, runtime: self) { try types.account.get() }
    }
    
    @inlinable
    func create<H: Hash>(hash: H.Type, raw: Data) throws -> H {
        try H(raw: raw, bits: { hasher.bitWidth })
    }
    
    @inlinable
    func create<S: Signature>(signature: S.Type, raw: Data, algorithm: CryptoTypeId) throws -> S {
        try S(raw: raw, algorithm: algorithm, runtime: self) { types.signature }
    }
    
    @inlinable
    func create<S: Signature>(fakeSignature: S.Type, algorithm: CryptoTypeId) throws -> S {
        try S(fake: algorithm, runtime: self) { types.signature }
    }
    
    @inlinable
    func algorithms<S: Signature>(signature: S.Type) throws -> [CryptoTypeId] {
        try S.algorithms(runtime: self) { types.signature }
    }
    
    @inlinable
    func decode<A: AccountId, D: ScaleCodec.Decoder>(
        account: A.Type, from decoder: inout D
    ) throws -> A {
        try decode(from: &decoder) { try types.account.get() }
    }
    
    @inlinable
    func encode<A: AccountId, E: ScaleCodec.Encoder>(
        account: A, in encoder: inout E
    ) throws {
        try encode(value: account, in: &encoder) { try types.account.get() }
    }
    
    @inlinable
    func decode<A: Address, D: ScaleCodec.Decoder>(
        address: A.Type, from decoder: inout D
    ) throws -> A {
        try decode(from: &decoder) { types.address }
    }
    
    @inlinable
    func encode<A: Address, E: ScaleCodec.Encoder>(
        address: A, in encoder: inout E
    ) throws {
        try encode(value: address, in: &encoder) { types.address }
    }
    
    @inlinable
    func decode<S: Signature, D: ScaleCodec.Decoder>(
        signature: S.Type, from decoder: inout D
    ) throws -> S {
        try decode(from: &decoder) { types.signature }
    }
    
    @inlinable
    func encode<S: Signature, E: ScaleCodec.Encoder>(
        signature: S, in encoder: inout E
    ) throws {
        try encode(value: signature, in: &encoder) { types.signature }
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

public protocol RuntimeValidatableType {
    func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
}
