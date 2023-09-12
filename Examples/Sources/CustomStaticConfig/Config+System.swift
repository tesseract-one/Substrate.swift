//
//  Config+System.swift
//  
//
//  Created by Yehor Popovych on 12/09/2023.
//

import Foundation
import Substrate
import ScaleCodec

extension Config {
    struct System: Frame {
        static var name: String = "System"
        
        var calls: [PalletCall.Type] {[
            ST<Config>.BatchCall.self, ST<Config>.BatchAllCall.self
        ]}
        
        var events: [PalletEvent.Type] {
            [ST<Config>.ExtrinsicFailureEvent.self,
             Event.ExtrinsicSuccess.self]
        }
        
        var storageKeys: [any PalletStorageKey.Type] {
            [Storage.Account.self, EventsStorageKey<ST<Config>.BlockEvents>.self]
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
                typealias TKH = CKH<ST<Config>.AccountId, HBlake2b128Concat>
                typealias TParams = ST<Config>.AccountId
                typealias TValue = Types.AccountInfo
                
                static var name: String { "Account" }
                
                let khPair: TKH
                init(khPair: TKH) { self.khPair = khPair }
            }
        }
        
        struct Types {
            struct AccountInfo: RuntimeCodable, IdentifiableType
            {
                let nonce: ST<Config>.Index
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
}

extension ExtrinsicEvents where R.RC == Config {
    var system: ExtrinsicEventsFrameFilter<R, Config.System> {
        _frame()
    }
}

extension ExtrinsicEventsFrameFilter where R.RC == Config, F == Config.System {
    var extrinsicSuccess: ExtrinsicEventsEventFilter<R, F.Event.ExtrinsicSuccess>  { _event() }
}

extension StorageApiRegistry where R.RC == Config {
    var system: FrameStorageApi<R, Config.System> { _frame() }
}

extension FrameStorageApi where R.RC == Config, F == Config.System {
    var account: StorageEntry<R, F.Storage.Account> { api.query.entry() }
}
