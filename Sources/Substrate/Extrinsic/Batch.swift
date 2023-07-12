//
//  Batch.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
import ScaleCodec

public protocol SomeBatchCall: IdentifiableCall {
    var calls: [any Call] { get }
    init(calls: [any Call])
    func add(_ call: any Call) -> Self
}

public protocol AnyBatchCallCommon: SomeBatchCall {}

public extension AnyBatchCallCommon {
    func add(_ call: any Call) -> Self { Self(calls: calls + [call]) }
    
    @inlinable static var pallet: String { "Utility" }
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: RuntimeType.Id, runtime: Runtime) throws {
        let calls = try Array<AnyCall>(from: &decoder) { decoder in
            try AnyCall(from: &decoder, as: type, runtime: runtime)
        }
        self.init(calls: calls)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, as type: RuntimeType.Id, runtime: Runtime) throws {
        try calls.encode(in: &encoder) { call, enc in
            try call.encode(in: &enc, runtime: runtime) { _ in type }
        }
    }
}

public struct AnyBatchCall: AnyBatchCallCommon {
    public let calls: [any Call]
    public init(calls: [any Call]) {
        self.calls = calls
    }
    public static let name = "batch"
}

public struct AnyBatchAllCall: AnyBatchCallCommon {
    public let calls: [any Call]
    public init(calls: [any Call]) {
        self.calls = calls
    }
    public static let name = "batch_all"
}

public protocol CallHolder<TCall> {
    associatedtype TCall: Call
    
    var call: TCall { get }
}
