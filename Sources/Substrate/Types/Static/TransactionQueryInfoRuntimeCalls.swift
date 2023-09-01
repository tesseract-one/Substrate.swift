//
//  TransactionQueryInfoRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation
import ScaleCodec

public protocol TransactionQueryRuntimeCallCommon: StaticRuntimeCall, RuntimeValidatable
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
    
    static func validate(runtime: any Runtime) -> Result<Void, ValidationError> {
        guard let info = runtime.resolve(runtimeCall: method, api: api) else {
            return .failure(.infoNotFound(for: Self.self))
        }
        guard info.params.count == 2 else {
            return .failure(.wrongFieldsCount(for: Self.self, expected: 2, got: info.params.count))
        }
        guard info.params[0].type.type.asBytes(runtime) != nil else {
            return .failure(.paramMismatch(for: Self.self,
                                           expected: "UncheckedExtrinsic",
                                           got: info.params[0].type.type.name ?? ""))
        }
        return UInt32.validate(runtime: runtime, type: info.params[1].type.id).flatMap {
            TReturn.validate(runtime: runtime, type: info.result.id)
        }.mapError { .childError(for: Self.self, error: $0) }
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
