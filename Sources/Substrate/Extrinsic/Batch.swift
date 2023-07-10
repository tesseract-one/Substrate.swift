//
//  Batch.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
import ScaleCodec

public protocol SomeBatchCall: StaticCall {
    var calls: [Call] { get }
    init(calls: [Call])
    func add(_ call: Call) -> Self
}

public extension SomeBatchCall {
    init<D: ScaleCodec.Decoder>(decodingParams decoder: inout D, runtime: Runtime) throws {
        let calls = try Array<AnyCall<RuntimeType.Id>>(from: &decoder, runtime: runtime)
        self.init(calls: calls)
    }
    
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try calls.encode(in: &encoder) { call, enc in
            try call.encode(in: &enc, runtime: runtime)
        }
    }
}

public protocol CallHolder<TCall> {
    associatedtype TCall: Call
    
    var call: TCall { get }
}
