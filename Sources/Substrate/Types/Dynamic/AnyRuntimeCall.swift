//
//  AnyRuntimeCall.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyRuntimeCall<Return: RuntimeLazyDynamicDecodable>: RuntimeCall {
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
            try value.asValue(of: param.type, in: runtime).encode(in: &encoder, runtime: runtime)
        }
    }
    
    public func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> Return {
        return try runtime.decode(from: &decoder) {
            guard let call = runtime.resolve(runtimeCall: method, api: api) else {
                throw RuntimeCallCodingError.callNotFound(method: method, api: api)
            }
            return call.result
        }
    }
}

public typealias AnyValueRuntimeCall = AnyRuntimeCall<Value<TypeDefinition>>
