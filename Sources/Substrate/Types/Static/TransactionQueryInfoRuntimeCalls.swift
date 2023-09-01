//
//  TransactionQueryInfoRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation
import ScaleCodec

public protocol TransactionQueryRuntimeCallCommon: StaticRuntimeCall, RuntimeValidatableStaticComposite
    where TReturn: RuntimeDynamicDecodable & RuntimeDynamicValidatable
{
    var extrinsic: Data { get }
}

public extension TransactionQueryRuntimeCallCommon {
    @inlinable
    static var api: String { "TransactionPaymentApi" }
    
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encoder.encode(extrinsic, .fixed(UInt(extrinsic.count)))
        try encoder.encode(UInt32(extrinsic.count))
    }
    
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D,
                                       runtime: Runtime) throws -> TReturn
    {
        try runtime.decode(from: &decoder) { runtime in
            guard let call = runtime.resolve(runtimeCall: Self.method, api: Self.api) else {
                throw RuntimeCallCodingError.callNotFound(method: method, api: api)
            }
            return call.result.id
        }
    }
    
    static var validatableFields: [RuntimeDynamicValidatable.Type] {
        [Data.self, UInt32.self]
    }
}

public struct TransactionQueryInfoRuntimeCall<DI>: TransactionQueryRuntimeCallCommon
    where DI: RuntimeDynamicDecodable & RuntimeDynamicValidatable
{
    public typealias TReturn = DI
    
    @inlinable
    public static var method: String { "query_info" }
    
    public let extrinsic: Data
    
    public init(extrinsic: Data) {
        self.extrinsic = extrinsic
    }
}

public struct TransactionQueryFeeDetailsRuntimeCall<FD>: TransactionQueryRuntimeCallCommon
    where FD: RuntimeDynamicDecodable & RuntimeDynamicValidatable
{
    public typealias TReturn = FD
    
    @inlinable
    public static var method: String { "query_fee_details" }
    
    public let extrinsic: Data
    
    public init(extrinsic: Data) {
        self.extrinsic = extrinsic
    }
}
