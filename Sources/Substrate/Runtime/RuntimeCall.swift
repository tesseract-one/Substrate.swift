//
//  RuntimeCall.swift
//  
//
//  Created by Yehor Popovych on 26.04.2023.
//

import Foundation
import ScaleCodec

public protocol RuntimeCall {
    associatedtype TReturn
    
    var api: String { get }
    var method: String { get }
    
    func encodeParams(in encoder: ScaleEncoder, runtime: Runtime) throws
    func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TReturn
}

public extension RuntimeCall {
    var fullName: String { "\(api)_\(method)" }
}

public protocol StaticRuntimeCall: RuntimeCall where TReturn: ScaleRuntimeDecodable {
    static var api: String { get }
    static var method: String { get }
}

public extension StaticRuntimeCall {
    var api: String { Self.api }
    var method: String { Self.method }
    
    func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TReturn {
        try TReturn(from: decoder, runtime: runtime)
    }
}

public protocol StaticCodableRuntimeCall: StaticRuntimeCall where TReturn: ScaleDecodable {
    func encodeParams(in encoder: ScaleEncoder) throws
    func decode(returnFrom decoder: ScaleDecoder) throws -> TReturn
}

public extension StaticCodableRuntimeCall {
    func encodeParams(in encoder: ScaleCodec.ScaleEncoder, runtime: Runtime) throws {
        try encodeParams(in: encoder)
    }
    
    func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> TReturn {
        try decode(returnFrom: decoder)
    }
    
    func decode(returnFrom decoder: ScaleDecoder) throws -> TReturn {
        try TReturn(from: decoder)
    }
}

public struct AnyRuntimeCall: RuntimeCall {
    public typealias TReturn = Value<RuntimeTypeId>
    
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
    
    public func decode(returnFrom decoder: ScaleDecoder, runtime: Runtime) throws -> Value<RuntimeTypeId> {
        guard let call = runtime.resolve(runtimeCall: method, api: api) else {
            throw RuntimeCallCodingError.callNotFound(method: method, api: api)
        }
        return try Value(from: decoder, as: call.result.id, runtime: runtime)
    }
}

public enum RuntimeCallCodingError: Error {
    case callNotFound(method: String, api: String)
    case expectedMapOrSequence(got: Value<Void>)
    case wrongParametersCount(params: [Value<Void>], expected: [(String, RuntimeTypeInfo)])
    case parameterNotFound(name: String, inParams: [String: Value<Void>])
}

public struct MetadataRuntimeApi {
    public struct Metadata: StaticCodableRuntimeCall {
        public typealias TReturn = Data
        static public let method = "metadata"
        static public var api: String { MetadataRuntimeApi.name }
        
        public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {}
    }
    
    public struct MetadataAtVersion: StaticCodableRuntimeCall {
        public typealias TReturn = Optional<Data>
        let version: UInt32
        
        public init(version: UInt32) {
            self.version = version
        }
        
        public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {
            try encoder.encode(version)
        }
        
        static public let method = "metadata_at_version"
        static public var api: String { MetadataRuntimeApi.name }
    }
    
    public struct MetadataVersions: StaticCodableRuntimeCall {
        public typealias TReturn = [UInt32]
        static public let method = "metadata_versions"
        static public var api: String { MetadataRuntimeApi.name }
        
        public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {}
    }
    
    public static let name = "Metadata"
}
