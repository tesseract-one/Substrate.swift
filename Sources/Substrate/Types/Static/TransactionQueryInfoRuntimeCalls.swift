//
//  TransactionQueryInfoRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation
import ScaleCodec

public struct TransactionQueryInfoRuntimeCall<DI: RuntimeDecodable>: StaticRuntimeCall {
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
}

public struct TransactionQueryFeeDetailsRuntimeCall<FD: RuntimeDecodable>: StaticRuntimeCall {
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
}
