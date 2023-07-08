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
    
    public let params: Value<Void>
    
    public init(api: String, method: String, params: Value<Void>) {
        self.api = api
        self.method = method
        self.params = params
    }
    
    public init(api: String, method: String) {
        self.init(api: api, method: method, params: .nil)
    }
    
    public init(api: String, method: String, param: any ValueRepresentable) throws {
        try self.init(api: api, method: method, params: param.asValue())
    }
    
    public init(api: String, method: String, map: [String: any ValueRepresentable]) throws {
        try self.init(api: api, method: method, params: .map(map))
    }
    
    public init(api: String, method: String, sequence: [any ValueRepresentable]) throws {
        try self.init(api: api, method: method, params: .sequence(sequence))
    }
    
    public init(api: String, method: String, from: any ValueMapRepresentable) throws {
        try self.init(api: api, method: method, params: .map(from: from))
    }
    
    public init(api: String, method: String, from: any ValueArrayRepresentable) throws {
        try self.init(api: api, method: method, params: .sequence(from: from))
    }
    
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let call = runtime.resolve(runtimeCall: method, api: api) else {
            throw RuntimeCallCodingError.callNotFound(method: method, api: api)
        }
        guard call.params.count > 0 else { return }
        if call.params.count == 1 {
            try params.encode(in: &encoder, as: call.params.first!.1.id, runtime: runtime)
        }
        switch params.value {
        case .sequence(let seq):
            guard seq.count == call.params.count else {
                throw RuntimeCallCodingError.wrongParametersCount(params: seq, expected: call.params)
            }
            for (param, info) in zip(seq, call.params) {
                try param.encode(in: &encoder, as: info.1.id, runtime: runtime)
            }
        case .map(let fields):
            for info in call.params {
                guard let param = fields[info.0] else {
                    throw RuntimeCallCodingError.parameterNotFound(name: info.0,
                                                                   inParams: fields)
                }
                try param.encode(in: &encoder, as: info.1.id, runtime: runtime)
            }
        default:
            throw RuntimeCallCodingError.expectedMapOrSequence(got: params)
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
    case expectedMapOrSequence(got: Value<Void>)
    case wrongParametersCount(params: [Value<Void>], expected: [(String, RuntimeType.Info)])
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
    where TReturn: RuntimeDynamicDecodable
{
    init(extrinsic: Data)
}

public protocol SomeTransactionPaymentFeeDetailsRuntimeCall<TReturn>: StaticRuntimeCall
    where TReturn: RuntimeDynamicDecodable
{    
    init(extrinsic: Data)
}
