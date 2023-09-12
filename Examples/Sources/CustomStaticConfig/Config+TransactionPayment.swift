//
//  Config+TransactionPayment.swift
//  
//
//  Created by Yehor Popovych on 13/09/2023.
//

import Foundation
import Substrate
import ScaleCodec

extension Config {
    struct TransactionPayment: Frame {
        static var name: String = "TransactionPayment"
        
        var events: [any PalletEvent.Type] {[
            Event.TransactionFeePaid.self
        ]}
        
        struct Event {
            struct TransactionFeePaid: FrameEvent, StaticEvent, IdentifiableFrameType {
                typealias TFrame = TransactionPayment
                static var name: String = "TransactionFeePaid"
                
                let who: ST<Config>.AccountId
                let actualFee: Balances.Types.Balance
                let tip: Balances.Types.Balance
                
                init<D>(paramsFrom decoder: inout D, runtime: Runtime) throws where D : Decoder {
                    who = try runtime.decode(from: &decoder)
                    actualFee = try decoder.decode()
                    tip = try decoder.decode()
                }
                
                static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                    .event(fields: [
                        .v(registry.def(ST<Config>.AccountId.self)),
                        .v(registry.def(Balances.Types.Balance.self)),
                        .v(registry.def(Balances.Types.Balance.self))
                    ])
                }
            }
        }
    }
}

extension ExtrinsicEvents where R.RC == Config {
    var transactionPayment: ExtrinsicEventsFrameFilter<R, Config.TransactionPayment> {
        _frame()
    }
}

extension ExtrinsicEventsFrameFilter where R.RC == Config, F == Config.TransactionPayment {
    var transactionFeePaid: ExtrinsicEventsEventFilter<R, F.Event.TransactionFeePaid>  {
        _event()
    }
}
