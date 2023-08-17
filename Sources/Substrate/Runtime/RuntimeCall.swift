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

public enum RuntimeCallCodingError: Error {
    case callNotFound(method: String, api: String)
    case wrongParametersCount(params: [String: any ValueRepresentable],
                              expected: [(String, RuntimeType.Info)])
    case parameterNotFound(name: String, inParams: [String: any ValueRepresentable])
}
