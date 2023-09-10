//
//  StaticTypes.swift
//  
//
//  Created by Yehor Popovych on 05/09/2023.
//

import Foundation
import Substrate
import ScaleCodec

extension Configs.Substrate {
    struct FrameSystem: Frame {
        typealias C = Configs.Substrate
        
        static var name: String { "System" }
        
        var calls: [PalletCall.Type] {[]}
        
        var events: [PalletEvent.Type] {
            [ST<C>.ExtrinsicFailureEvent.self]
        }
        
        var storageKeys: [any PalletStorageKey.Type] {
            [Storage.Account<ST<C>.AccountId,
                            Types.AccountInfo<ST<C>.Index, Types.AccountData<Types.Balance>>>.self]
        }
        
        var constants: [any StaticConstant.Type] { [] }
        
        
        struct Storage {
            struct Account<A: StaticAccountId,
                           Info: RuntimeCodable & IdentifiableType>: FrameStorageKey, MapStorageKey, IdentifiableFrameType {
                typealias TFrame = FrameSystem
                typealias TKH = CKH<A, HBlake2b128Concat>
                typealias TParams = A
                typealias TValue = Info
                
                static var name: String { "Account" }
                
                let khPair: TKH
                init(khPair: TKH) { self.khPair = khPair }
            }
        }
        
        struct Types {
            public typealias Balance = UInt128
            
            struct AccountInfo<N: ConfigUnsignedInteger,
                               D: RuntimeCodable & IdentifiableType>: RuntimeCodable, IdentifiableType
            {
                let nonce: N
                let consumers: UInt64
                let providers: UInt64
                let sufficients: UInt64
                let data: D
                
                init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws{
                    nonce = try runtime.decode(from: &decoder)
                    consumers = try decoder.decode()
                    providers = try decoder.decode()
                    sufficients = try decoder.decode()
                    data = try runtime.decode(from: &decoder)
                }
                
                func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
                    try runtime.encode(value: nonce, in: &encoder)
                    try encoder.encode(consumers)
                    try encoder.encode(providers)
                    try encoder.encode(sufficients)
                    try runtime.encode(value: data, in: &encoder)
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
                    .composite(fields: [
                        .v(registry.def(N.self)), .v(registry.def(UInt64.self)),
                        .v(registry.def(UInt64.self)),
                        .v(registry.def(UInt64.self)), .v(registry.def(D.self))
                    ])
                }
            }
            
            struct AccountData<B: ConfigUnsignedInteger>: RuntimeCodable, IdentifiableType {
                let free: B
                let reserved: B
                let frozen: B
                let flags: UInt128
                
                init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws  {
                    free = try runtime.decode(from: &decoder)
                    reserved = try runtime.decode(from: &decoder)
                    frozen = try runtime.decode(from: &decoder)
                    flags = try runtime.decode(from: &decoder)
                }
                
                func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
                    try runtime.encode(value: free, in: &encoder)
                    try runtime.encode(value: reserved, in: &encoder)
                    try runtime.encode(value: frozen, in: &encoder)
                    try runtime.encode(value: flags, in: &encoder)
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
                    .composite(fields: [
                        .v(registry.def(B.self)), .v(registry.def(B.self)),
                        .v(registry.def(B.self)),
                        .v(registry.def(UInt128.self))
                    ])
                }
            }
        }
    }
}
