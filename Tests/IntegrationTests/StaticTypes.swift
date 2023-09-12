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
    struct System: Frame {
        typealias C = Configs.Substrate
        
        static var name: String { "System" }
        
        var calls: [PalletCall.Type] {[
            ST<C>.BatchCall.self, ST<C>.BatchAllCall.self
        ]}
        
        var events: [PalletEvent.Type] {
            [ST<C>.ExtrinsicFailureEvent.self,
             Event.ExtrinsicSuccess.self]
        }
        
        var storageKeys: [any PalletStorageKey.Type] {
            [Storage.Account.self, EventsStorageKey<ST<C>.BlockEvents>.self]
        }
        
        struct Event {
            struct ExtrinsicSuccess: FrameEvent, StaticEvent, IdentifiableFrameType {
                typealias TFrame = System
                static var name: String = "ExtrinsicSuccess"
                
                let dispatchInfo: DispatchInfo
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    dispatchInfo = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(DispatchInfo.self))
                    ])
                }
            }
        }
        
        struct Storage {
            struct Account: FrameStorageKey, MapStorageKey, IdentifiableFrameType {
                typealias TFrame = System
                typealias TKH = CKH<ST<C>.AccountId, HBlake2b128Concat>
                typealias TParams = ST<C>.AccountId
                typealias TValue = Types.AccountInfo
                
                static var name: String { "Account" }
                
                let khPair: TKH
                init(khPair: TKH) { self.khPair = khPair }
            }
        }
        
        struct Types {
            struct AccountInfo: RuntimeCodable, IdentifiableType
            {
                let nonce: ST<C>.Index
                let consumers: UInt32
                let providers: UInt32
                let sufficients: UInt32
                let data: Balances.Types.AccountData
                
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
                        .v(registry.def(ST<Configs.Substrate>.Index.self)),
                        .v(registry.def(UInt32.self)),
                        .v(registry.def(UInt32.self)),
                        .v(registry.def(UInt32.self)),
                        .v(registry.def(Balances.Types.AccountData.self))
                    ])
                }
            }
        }
    }
    
    struct Balances: Frame {
        typealias C = Configs.Substrate
        
        static var name: String { "Balances" }
        
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
                
                let who: ST<C>.AccountId
                let amount: Types.Balance
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    who = try runtime.decode(from: &decoder)
                    amount = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(ST<C>.AccountId.self)),
                        .v(registry.def(Types.Balance.self))
                    ])
                }
            }
            
            struct Transfer: FrameEvent, StaticEvent, IdentifiableFrameType {
                typealias TFrame = Balances
                static var name: String = "Transfer"
                
                let from: ST<C>.AccountId
                let to: ST<C>.AccountId
                let amount: Types.Balance
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    from = try runtime.decode(from: &decoder)
                    to = try runtime.decode(from: &decoder)
                    amount = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(ST<C>.AccountId.self)),
                        .v(registry.def(ST<C>.AccountId.self)),
                        .v(registry.def(Types.Balance.self))
                    ])
                }
            }
        }
        
        struct Call {
            struct TransferAllowDeath: StaticCall, FrameCall, IdentifiableFrameType {
                typealias TFrame = Balances
                static var name: String = "transfer_allow_death"
                
                let dest: ST<C>.Address
                let value: Types.Balance
                
                init(dest: ST<C>.Address, value: Types.Balance) {
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
                        .v(registry.def(ST<C>.Address.self)),
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
    
    struct TransactionPayment: Frame {
        typealias C = Configs.Substrate
        
        static var name: String = "TransactionPayment"
        
        var events: [any PalletEvent.Type] {[
            Event.TransactionFeePaid.self
        ]}
        
        struct Event {
            struct TransactionFeePaid: FrameEvent, StaticEvent, IdentifiableFrameType {
                typealias TFrame = TransactionPayment
                static var name: String = "TransactionFeePaid"
                
                let who: ST<C>.AccountId
                let actualFee: Balances.Types.Balance
                let tip: Balances.Types.Balance
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    who = try runtime.decode(from: &decoder)
                    actualFee = try decoder.decode()
                    tip = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(ST<C>.AccountId.self)),
                        .v(registry.def(Balances.Types.Balance.self)),
                        .v(registry.def(Balances.Types.Balance.self))
                    ])
                }
            }
        }
    }
    
    struct TransactionPaymentApi: RuntimeApiFrame {
        typealias C = Configs.Substrate
        
        static var name: String = "TransactionPaymentApi"
        
        var calls: [any StaticRuntimeCall.Type] {
            [QueryInfo.self, QueryFeeDetails.self]
        }
        
        struct QueryInfo: RuntimeApiFrameCall, IdentifiableFrameType {
            typealias TApi = TransactionPaymentApi
            typealias TReturn = ST<C>.RuntimeDispatchInfo
            
            static var method: String = "query_info"
            
            let uxt: Data
            let len: UInt32
            
            public init(extrinsic: Data) {
                uxt = extrinsic
                len = UInt32(extrinsic.count)
            }
            
            public init<CL: Call>(extrinsic: ST<C>.SignedExtrinsic<CL>, runtime: ExtendedRuntime<C>) throws {
                var encoder = runtime.encoder()
                try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: runtime)
                self.init(extrinsic: encoder.output)
            }
            
            func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
                try encoder.encode(uxt, .fixed(UInt(len)))
                try encoder.encode(len)
            }
            
            static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                .runtimeCall(params: [
                    .v(registry.def(Data.self, .dynamic)),
                    .v(registry.def(UInt32.self))
                ], return: registry.def(ST<C>.RuntimeDispatchInfo.self))
            }
        }
        
        struct QueryFeeDetails: RuntimeApiFrameCall, IdentifiableFrameType {
            typealias TApi = TransactionPaymentApi
            typealias TReturn = ST<C>.FeeDetails
            
            static var method: String = "query_fee_details"
            
            let uxt: Data
            let len: UInt32
            
            public init(extrinsic: Data) {
                uxt = extrinsic
                len = UInt32(extrinsic.count)
            }
            
            public init<CL: Call>(extrinsic: ST<C>.SignedExtrinsic<CL>, runtime: ExtendedRuntime<C>) throws {
                var encoder = runtime.encoder()
                try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: runtime)
                self.init(extrinsic: encoder.output)
            }
            
            func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
                try encoder.encode(uxt, .fixed(UInt(len)))
                try encoder.encode(len)
            }
            
            static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                .runtimeCall(params: [
                    .v(registry.def(Data.self, .dynamic)),
                    .v(registry.def(UInt32.self))
                ], return: registry.def(ST<C>.FeeDetails.self))
            }
        }
    }
}

extension RuntimeCallApiRegistry where R.RC == Configs.Substrate {
    var transaction: FrameRuntimeCallApi<R, Configs.Substrate.TransactionPaymentApi> { _frame() }
}

extension FrameRuntimeCallApi where R.RC == Configs.Substrate,
                                    F == Configs.Substrate.TransactionPaymentApi
{
    func queryInfo<C: Call>(extrinsic: ST<R.RC>.SignedExtrinsic<C>) async throws -> F.QueryInfo.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = F.QueryInfo(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
    
    func queryInfo<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra>, from: any PublicKey
    ) async throws -> F.QueryInfo.TReturn {
        let signed = try await tx.fakeSign(account: from)
        return try await queryInfo(tx: signed)
    }
    
    func queryInfo<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicSignedExtra>
    ) async throws -> F.QueryInfo.TReturn {
        try await queryInfo(extrinsic: tx.extrinsic)
    }
    
    func queryFeeDetails<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra>, from: any PublicKey
    ) async throws -> F.QueryFeeDetails.TReturn {
        let signed = try await tx.fakeSign(account: from)
        return try await queryFeeDetails(tx: signed)
    }
    
    func queryFeeDetails<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicSignedExtra>
    ) async throws -> F.QueryFeeDetails.TReturn {
        try await queryFeeDetails(extrinsic: tx.extrinsic)
    }
    
    func queryFeeDetails<C: Call>(
        extrinsic: ST<R.RC>.SignedExtrinsic<C>
    ) async throws -> F.QueryFeeDetails.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = F.QueryFeeDetails(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
}

extension ExtrinsicApiRegistry where R.RC == Configs.Substrate {
    var balances: FrameExtrinsicApi<R, Configs.Substrate.Balances> { _frame() }
}

extension FrameExtrinsicApi where R.RC == Configs.Substrate, F == Configs.Substrate.Balances {
    func callTransferAllowDeath(
        dest: ST<R.RC>.Address, value: F.Types.Balance
    ) -> F.Call.TransferAllowDeath {
        F.Call.TransferAllowDeath(dest: dest, value: value)
    }
    
    func transferAllowDeath(
        dest: ST<R.RC>.Address, value: F.Types.Balance
    ) async throws -> Submittable<R, F.Call.TransferAllowDeath, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await api.tx.new(F.Call.TransferAllowDeath(dest: dest, value: value))
    }
}

extension ExtrinsicEvents where R.RC == Configs.Substrate {
    var system: ExtrinsicEventsFrameFilter<R, Configs.Substrate.System> {
        _frame()
    }
    var transactionPayment: ExtrinsicEventsFrameFilter<R, Configs.Substrate.TransactionPayment> {
        _frame()
    }
    var balances: ExtrinsicEventsFrameFilter<R, Configs.Substrate.Balances> {
        _frame()
    }
}

extension ExtrinsicEventsFrameFilter where R.RC == Configs.Substrate, F == Configs.Substrate.System {
    var extrinsicSuccess: ExtrinsicEventsEventFilter<R, F.Event.ExtrinsicSuccess>  { _event() }
}

extension ExtrinsicEventsFrameFilter where R.RC == Configs.Substrate, F == Configs.Substrate.TransactionPayment {
    var transactionFeePaid: ExtrinsicEventsEventFilter<R, F.Event.TransactionFeePaid>  { _event() }
}

extension ExtrinsicEventsFrameFilter where R.RC == Configs.Substrate, F == Configs.Substrate.Balances {
    var transfer: ExtrinsicEventsEventFilter<R, F.Event.Transfer>  { _event() }
    var withdraw: ExtrinsicEventsEventFilter<R, F.Event.Withdraw>  { _event() }
}

extension StorageApiRegistry where R.RC == Configs.Substrate {
    var system: FrameStorageApi<R, Configs.Substrate.System> { _frame() }
}

extension FrameStorageApi where R.RC == Configs.Substrate, F == Configs.Substrate.System {
    var account: StorageEntry<R, F.Storage.Account> { api.query.entry() }
}
