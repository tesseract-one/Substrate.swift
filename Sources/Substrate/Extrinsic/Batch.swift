//
//  Batch.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
import ScaleCodec

public protocol SomeBatchCall: IdentifiableCall {
    var calls: [Call] { get }
    init(calls: [Call])
    func add(_ call: Call) -> Self
}

public struct AnyBatchCall: SomeBatchCall {
    public let calls: [Call]
    public init(calls: [Call]) {
        self.calls = calls
    }
    public func add(_ call: Call) -> AnyBatchCall {
        Self(calls: calls + [call])
    }
    public static var name: String = "batch"
    public static var pallet: String = "Utility"
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        calls = try Array<AnyCall<RuntimeType.Id>>(from: &decoder) { decoder in
            try AnyCall<RuntimeType.Id>(from: &decoder, runtime: runtime) { _ in type }
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                              as type: RuntimeType.Id,
                                              runtime: Runtime) throws
    {
        try calls.encode(in: &encoder) { call, enc in
            try call.encode(in: &enc, runtime: runtime) { _ in type }
        }
    }
}

public struct AnyBatchAllCall: SomeBatchCall {
    public let calls: [Call]
    public init(calls: [Call]) {
        self.calls = calls
    }
    public func add(_ call: Call) -> Self {
        Self(calls: calls + [call])
    }
    public static var name = "batch_all"
    public static var pallet = "Utility"
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        calls = try Array<AnyCall<RuntimeType.Id>>(from: &decoder) { decoder in
            try AnyCall<RuntimeType.Id>(from: &decoder, runtime: runtime) { _ in type }
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                              as type: RuntimeType.Id,
                                              runtime: Runtime) throws
    {
        try calls.encode(in: &encoder) { call, enc in
            try call.encode(in: &enc, runtime: runtime) { _ in type }
        }
    }
}

public protocol CallHolder<TCall> {
    associatedtype TCall: Call
    
    var call: TCall { get }
}
