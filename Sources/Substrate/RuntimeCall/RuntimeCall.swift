//
//  RuntimeCall.swift
//  
//
//  Created by Yehor Popovych on 26.04.2023.
//

import Foundation
import ScaleCodec

public protocol RuntimeCall<TReturn> {
    associatedtype TReturn
    
    var api: String { get }
    var method: String { get }
    
    func encodeParams(in encoder: ScaleEncoder, runtime: Runtime) throws
    func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TReturn
}

public extension RuntimeCall {
    var fullName: String { "\(api)_\(method)" }
}

public protocol StaticRuntimeCall: RuntimeCall {
    static var api: String { get }
    static var method: String { get }
}

public extension StaticRuntimeCall {
    var api: String { Self.api }
    var method: String { Self.method }
}

public extension StaticRuntimeCall where TReturn: ScaleRuntimeDecodable {
    func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TReturn {
        try TReturn(from: decoder, runtime: runtime)
    }
}

public protocol StaticCodableRuntimeCall: StaticRuntimeCall where TReturn: ScaleDecodable {
    func encodeParams(in encoder: ScaleEncoder) throws
    func decode(returnFrom decoder: ScaleDecoder) throws -> TReturn
}

public extension StaticCodableRuntimeCall {
    func encodeParams(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encodeParams(in: encoder)
    }
    
    func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TReturn {
        try decode(returnFrom: decoder)
    }
    
    func decode(returnFrom decoder: ScaleDecoder) throws -> TReturn {
        try TReturn(from: decoder)
    }
}

public struct AnyRuntimeCall<Return: ScaleRuntimeDynamicDecodable>: RuntimeCall {
    public typealias TReturn = Return
    
    public let api: String
    public let method: String
    
    public let params: Value<Void>
    
    public init(api: String, method: String, params: Value<Void>) {
        self.api = api
        self.method = method
        self.params = params
    }
    
    public func encodeParams(in encoder: ScaleEncoder, runtime: Runtime) throws {
        guard let call = runtime.resolve(runtimeCall: method, api: api) else {
            throw RuntimeCallCodingError.callNotFound(method: method, api: api)
        }
        guard call.params.count > 0 else { return }
        if call.params.count == 1 {
            try params.encode(in: encoder, as: call.params.first!.1.id, runtime: runtime)
        }
        switch params.value {
        case .sequence(let seq):
            guard seq.count == call.params.count else {
                throw RuntimeCallCodingError.wrongParametersCount(params: seq, expected: call.params)
            }
            for (param, info) in zip(seq, call.params) {
                try param.encode(in: encoder, as: info.1.id, runtime: runtime)
            }
        case .map(let fields):
            for info in call.params {
                guard let param = fields[info.0] else {
                    throw RuntimeCallCodingError.parameterNotFound(name: info.0,
                                                                   inParams: fields)
                }
                try param.encode(in: encoder, as: info.1.id, runtime: runtime)
            }
        default:
            throw RuntimeCallCodingError.expectedMapOrSequence(got: params)
        }
    }
    
    public func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> Return {
        return try Return(from: decoder, runtime: runtime) { runtime in
            guard let call = runtime.resolve(runtimeCall: method, api: api) else {
                throw RuntimeCallCodingError.callNotFound(method: method, api: api)
            }
            return call.result.id
        }
    }
}

public typealias AnyValueRuntimeCall = AnyRuntimeCall<Value<RuntimeTypeId>>

public enum RuntimeCallCodingError: Error {
    case callNotFound(method: String, api: String)
    case expectedMapOrSequence(got: Value<Void>)
    case wrongParametersCount(params: [Value<Void>], expected: [(String, RuntimeTypeInfo)])
    case parameterNotFound(name: String, inParams: [String: Value<Void>])
}

public protocol SomeMetadataVersionsRuntimeCall: StaticCodableRuntimeCall
    where TReturn == [UInt32]
{
    init()
}

public protocol SomeMetadataAtVersionRuntimeCall: StaticCodableRuntimeCall
    where TReturn == Optional<OpaqueMetadata>
{
    init(version: UInt32)
}

public protocol SomeTransactionPaymentQueryInfoRuntimeCall<TReturn>: StaticRuntimeCall
    where TReturn: ScaleRuntimeDynamicDecodable
{
    init(extrinsic: Data)
}

public protocol SomeTransactionPaymentFeeDetailsRuntimeCall<TReturn>: StaticRuntimeCall
    where TReturn: ScaleRuntimeDynamicDecodable
{    
    init(extrinsic: Data)
}
