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

public protocol StaticRuntimeCall<TReturn>: RuntimeCall {
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

public protocol StaticCodableRuntimeCall<TReturn>: StaticRuntimeCall where TReturn: ScaleCodec.Decodable {
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
        self.init(api: api, method: method, params: [param])
    }
    
    public init(api: String, method: String, params: [any ValueRepresentable]) {
        let pairs = params.enumerated().map{(String($0.offset), $0.element)}
        self.init(api: api, method: method, params: Dictionary(uniqueKeysWithValues: pairs))
    }
    
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let call = runtime.resolve(runtimeCall: method, api: api) else {
            throw RuntimeCallCodingError.callNotFound(method: method, api: api)
        }
        guard call.params.count > 0 else { return }
        guard params.count == call.params.count else {
            throw RuntimeCallCodingError.wrongParametersCount(params: params, expected: call.params)
        }
        for (idx, param) in call.params.enumerated() {
            let value: ValueRepresentable
            if let val = params[param.name] {
                value = val
            } else if let val = params[String(idx)] {
                value = val
            } else {
                throw RuntimeCallCodingError.parameterNotFound(name: param.name, inParams: params)
            }
            try value.asValue(runtime: runtime, type: param.type.id)
                .encode(in: &encoder, as: param.type.id, runtime: runtime)
        }
    }
    
    public func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> Return {
        return try runtime.decode(from: &decoder) { runtime in
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

public struct MetadataVersionsRuntimeCall: StaticCodableRuntimeCall {
    public typealias TReturn = [UInt32]
    public static let method = "metadata_versions"
    public static let api = "Metadata"
    
    public init() {}
    public func encodeParams<E>(in encoder: inout E) throws where E : ScaleCodec.Encoder {}
}

public struct MetadataAtVersionRuntimeCall: StaticCodableRuntimeCall {
    public typealias TReturn = Optional<OpaqueMetadata>
    public static let method = "metadata_at_version"
    public static let api = "Metadata"
    
    public let version: UInt32
    
    public init(version: UInt32) { self.version = version }
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(version)
    }
}
