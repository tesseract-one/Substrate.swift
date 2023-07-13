//
//  RuntimeTypes.swift
//  
//
//  Created by Yehor Popovych on 07/07/2023.
//

import Foundation
import ScaleCodec

public extension RuntimeType {
    typealias LazyId = (Runtime) throws -> Id
    
    struct IdNeverCalledError: Error, CustomStringConvertible {
        public var description: String { "Asked for IdNever" }
        public init() {}
    }
    
    static func IdNever(_ r: Runtime) throws -> RuntimeType.Id { throw IdNeverCalledError() }
}

public protocol RuntimeTypes {
    var block: RuntimeType.Info { get throws }
    var account: RuntimeType.Info { get throws }
    var address: RuntimeType.Info { get throws }
    var signature: RuntimeType.Info { get throws }
    var call: RuntimeType.Info { get throws }
    var event: RuntimeType.Info { get throws }
    var extrinsicExtra: RuntimeType.Info { get throws }
    var dispatchInfo: RuntimeType.Info { get throws }
    var dispatchError: RuntimeType.Info { get throws }
    var feeDetails: RuntimeType.Info { get throws }
    var transactionValidityError: RuntimeType.Info { get throws }
}

public extension Runtime {
    @inlinable
    func decode<E: Event>(event: E.Type, from data: Data) throws -> E {
        try decode(from: data) { try $0.types.event.id }
    }
    
    @inlinable
    func decode<E: Event, D: ScaleCodec.Decoder>(
        event: E.Type, from decoder: inout D
    ) throws -> E {
        try decode(from: &decoder) { try $0.types.event.id }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, pub: any PublicKey) throws -> A {
        try A(pub: pub, runtime: self) { try $0.types.account.id }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, raw: Data) throws -> A {
        try A(raw: raw, runtime: self) { try $0.types.account.id }
    }
    
    @inlinable
    func create<A: AccountId>(account: A.Type, from string: String) throws -> A {
        try A(from: string, runtime: self) { try $0.types.account.id }
    }
    
    @inlinable
    func create<A: Address>(address: A.Type, account: A.TAccountId) throws -> A {
        try A(accountId: account, runtime: self) { try $0.types.account.id }
    }
    
    @inlinable
    func create<S: Signature>(signature: S.Type, raw: Data, algorithm: CryptoTypeId) throws -> S {
        try S(raw: raw, algorithm: algorithm, runtime: self) { try $0.types.signature.id }
    }
    
    @inlinable
    func create<S: Signature>(fakeSignature: S.Type, algorithm: CryptoTypeId) throws -> S {
        try S(fake: algorithm, runtime: self) { try $0.types.signature.id }
    }
    
    @inlinable
    func algorithms<S: Signature>(signature: S.Type) throws -> [CryptoTypeId] {
        try S.algorithms(runtime: self) { try $0.types.signature.id }
    }
    
    @inlinable
    func decode<A: AccountId, D: ScaleCodec.Decoder>(
        account: A.Type, from decoder: inout D
    ) throws -> A {
        try decode(from: &decoder) { try $0.types.account.id }
    }
    
    @inlinable
    func encode<A: AccountId, E: ScaleCodec.Encoder>(
        account: A, in encoder: inout E
    ) throws {
        try account.encode(in: &encoder, runtime: self) { try $0.types.account.id }
    }
    
    @inlinable
    func decode<A: Address, D: ScaleCodec.Decoder>(
        address: A.Type, from decoder: inout D
    ) throws -> A {
        try decode(from: &decoder) { try $0.types.address.id }
    }
    
    @inlinable
    func encode<A: Address, E: ScaleCodec.Encoder>(
        address: A, in encoder: inout E
    ) throws {
        try address.encode(in: &encoder, runtime: self) { try $0.types.address.id }
    }
    
    @inlinable
    func decode<S: Signature, D: ScaleCodec.Decoder>(
        signature: S.Type, from decoder: inout D
    ) throws -> S {
        try decode(from: &decoder) { try $0.types.signature.id }
    }
    
    @inlinable
    func encode<S: Signature, E: ScaleCodec.Encoder>(
        signature: S, in encoder: inout E
    ) throws {
        try signature.encode(in: &encoder, runtime: self) { try $0.types.signature.id }
    }
    
    @inlinable
    func decode<C: Call & RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        call: C.Type, from decoder: inout D
    ) throws -> C {
        try decode(from: &decoder) { try $0.types.call.id }
    }
    
    @inlinable
    func encode<C: Call, E: ScaleCodec.Encoder>(
        call: C, in encoder: inout E
    ) throws {
        try call.encode(in: &encoder, runtime: self) { try $0.types.call.id }
    }
}
