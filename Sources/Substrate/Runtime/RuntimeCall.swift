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
    
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> TReturn
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

public extension StaticRuntimeCall where TReturn: RuntimeDecodable {
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> TReturn {
        try TReturn(from: &decoder, runtime: runtime)
    }
}

public protocol StaticCodableRuntimeCall: StaticRuntimeCall where TReturn: ScaleCodec.Decodable {
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E) throws
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D) throws -> TReturn
}

public extension StaticCodableRuntimeCall {
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encodeParams(in: &encoder)
    }
    
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> TReturn {
        try decode(returnFrom: &decoder)
    }
    
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D) throws -> TReturn {
        try TReturn(from: &decoder)
    }
}

public struct AnyRuntimeCall<Return: RuntimeDynamicDecodable>: RuntimeCall {
    public typealias TReturn = Return
    
    public let api: String
    public let method: String
    
    public let params: [String: any ValueRepresentable]
    
    public init(api: String, method: String, params: [String: any ValueRepresentable]) {
        self.api = api
        self.method = method
        self.params = params
    }
    
    public init(api: String, method: String) {
        self.init(api: api, method: method, params: [:])
    }
    
    public init(api: String, method: String, param: any ValueRepresentable) {
        self.init(api: api, method: method, params: ["": param])
    }
    
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let call = runtime.resolve(runtimeCall: method, api: api) else {
            throw RuntimeCallCodingError.callNotFound(method: method, api: api)
        }
        guard call.params.count > 0 else { return }
        guard params.count == call.params.count else {
            throw RuntimeCallCodingError.wrongParametersCount(params: params, expected: call.params)
        }
        if call.params.count == 1 {
            try params.first!.value.asValue(runtime: runtime, type: call.params.first!.type.id)
                .encode(in: &encoder, as: call.params.first!.type.id, runtime: runtime)
        } else {
            for param in call.params {
                guard let val = params[param.name] else {
                    throw RuntimeCallCodingError.parameterNotFound(name: param.name, inParams: params)
                }
                try val.asValue(runtime: runtime, type: param.type.id)
                    .encode(in: &encoder, as: param.type.id, runtime: runtime)
            }
        }
    }
    
    public func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> Return {
        return try Return(from: &decoder, runtime: runtime) { runtime in
            guard let call = runtime.resolve(runtimeCall: method, api: api) else {
                throw RuntimeCallCodingError.callNotFound(method: method, api: api)
            }
            return call.result.id
        }
    }
}

public typealias AnyValueRuntimeCall = AnyRuntimeCall<Value<RuntimeType.Id>>

public enum RuntimeCallCodingError: Error {
    case callNotFound(method: String, api: String)
    case wrongParametersCount(params: [String: any ValueRepresentable],
                              expected: [(String, RuntimeType.Info)])
    case parameterNotFound(name: String, inParams: [String: any ValueRepresentable])
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
    where TReturn: RuntimeDynamicDecodable
{
    init(extrinsic: Data)
}

public protocol SomeTransactionPaymentFeeDetailsRuntimeCall<TReturn>: StaticRuntimeCall
    where TReturn: RuntimeDynamicDecodable
{    
    init(extrinsic: Data)
}
