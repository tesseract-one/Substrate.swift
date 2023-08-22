//
//  TransactionQueryInfoRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation
import ScaleCodec

public struct TransactionQueryInfoRuntimeCall<DI: RuntimeDynamicDecodable>: StaticRuntimeCall {
    public typealias TReturn = DI
    
    @inlinable
    public static var api: String { "TransactionPaymentApi" }
    @inlinable
    public static var method: String { "query_info" }
    
    public let extrinsic: Data
    
    public init(extrinsic: Data) {
        self.extrinsic = extrinsic
    }
    
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encoder.encode(extrinsic, .fixed(UInt(extrinsic.count)))
        try encoder.encode(UInt32(extrinsic.count))
    }
    
    public func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D,
                                              runtime: Runtime) throws -> TReturn
    {
        try runtime.decode(from: &decoder) { runtime in
            guard let call = runtime.resolve(runtimeCall: Self.method, api: Self.api) else {
                throw RuntimeCallCodingError.callNotFound(method: method, api: api)
            }
            return call.result.id
        }
    }
}

public struct TransactionQueryFeeDetailsRuntimeCall<FD: RuntimeDynamicDecodable>: StaticRuntimeCall {
    public typealias TReturn = FD
    
    @inlinable
    public static var api: String { "TransactionPaymentApi" }
    @inlinable
    public static var method: String { "query_fee_details" }
    
    public let extrinsic: Data
    
    public init(extrinsic: Data) {
        self.extrinsic = extrinsic
    }
    
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encoder.encode(extrinsic, .fixed(UInt(extrinsic.count)))
        try encoder.encode(UInt32(extrinsic.count))
    }
    
    public func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D,
                                              runtime: Runtime) throws -> TReturn
    {
        try runtime.decode(from: &decoder) { runtime in
            guard let call = runtime.resolve(runtimeCall: Self.method, api: Self.api) else {
                throw RuntimeCallCodingError.callNotFound(method: method, api: api)
            }
            return call.result.id
        }
    }
}
