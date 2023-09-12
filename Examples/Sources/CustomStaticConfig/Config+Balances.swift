//
//  Config+Balances.swift
//  
//
//  Created by Yehor Popovych on 13/09/2023.
//

import Foundation
import Substrate
import ScaleCodec

extension Config {
    struct Balances: Frame {
        static var name: String = "Balances"
        
        var calls: [any PalletCall.Type] {[
            Call.TransferAllowDeath.self
        ]}
        
        var events: [any PalletEvent.Type] {[
            Event.Transfer.self, Event.Withdraw.self
        ]}
        
        struct Event {
            struct Withdraw: FrameEvent, StaticEvent, IdentifiableFrameType {
                typealias TFrame = Balances
                static var name: String = "Withdraw"
                
                let who: ST<Config>.AccountId
                let amount: Types.Balance
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    who = try runtime.decode(from: &decoder)
                    amount = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(ST<Config>.AccountId.self)),
                        .v(registry.def(Types.Balance.self))
                    ])
                }
            }
            
            struct Transfer: FrameEvent, StaticEvent, IdentifiableFrameType {
                typealias TFrame = Balances
                static var name: String = "Transfer"
                
                let from: ST<Config>.AccountId
                let to: ST<Config>.AccountId
                let amount: Types.Balance
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    from = try runtime.decode(from: &decoder)
                    to = try runtime.decode(from: &decoder)
                    amount = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(ST<Config>.AccountId.self)),
                        .v(registry.def(ST<Config>.AccountId.self)),
                        .v(registry.def(Types.Balance.self))
                    ])
                }
            }
        }
        
        struct Call {
            struct TransferAllowDeath: StaticCall, FrameCall, IdentifiableFrameType {
                typealias TFrame = Balances
                static var name: String = "transfer_allow_death"
                
                let dest: ST<Config>.Address
                let value: Types.Balance
                
                init(dest: ST<Config>.Address, value: Types.Balance) {
                    self.dest = dest
                    self.value = value
                }
                
                init<D: ScaleCodec.Decoder>(decodingParams decoder: inout D, runtime: Runtime) throws {
                    dest = try runtime.decode(from: &decoder)
                    value = try decoder.decode(.compact)
                }
                
                func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
                    try runtime.encode(value: dest, in: &encoder)
                    try encoder.encode(value, .compact)
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .call(fields: [
                        .v(registry.def(ST<Config>.Address.self)),
                        .v(registry.def(compact: Types.Balance.self))
                    ])
                }
            }
        }
        
        struct Types {
            typealias Balance = UInt128
            
            struct AccountData: RuntimeCodable, IdentifiableType {
                let free: Balance
                let reserved: Balance
                let frozen: Balance
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
                        .v(registry.def(Balance.self)), .v(registry.def(Balance.self)),
                        .v(registry.def(Balance.self)), .v(registry.def(UInt128.self))
                    ])
                }
            }
        }
    }
}

extension ExtrinsicApiRegistry where R.RC == Config {
    var balances: FrameExtrinsicApi<R, Config.Balances> { _frame() }
}

extension FrameExtrinsicApi where R.RC == Config, F == Config.Balances {
    func callTransferAllowDeath(
        dest: ST<R.RC>.Address, value: F.Types.Balance
    ) -> F.Call.TransferAllowDeath {
        F.Call.TransferAllowDeath(dest: dest, value: value)
    }
    
    func transferAllowDeath(
        dest: ST<R.RC>.Address, value: F.Types.Balance
    ) async throws -> Submittable<R, F.Call.TransferAllowDeath,
                                  ST<R.RC>.ExtrinsicUnsignedExtra>
    {
        try await api.tx.new(F.Call.TransferAllowDeath(dest: dest, value: value))
    }
}

extension ExtrinsicEvents where R.RC == Config{
    var balances: ExtrinsicEventsFrameFilter<R, Config.Balances> {
        _frame()
    }
}

extension ExtrinsicEventsFrameFilter where R.RC == Config, F == Config.Balances {
    var transfer: ExtrinsicEventsEventFilter<R, F.Event.Transfer>  { _event() }
    var withdraw: ExtrinsicEventsEventFilter<R, F.Event.Withdraw>  { _event() }
}
