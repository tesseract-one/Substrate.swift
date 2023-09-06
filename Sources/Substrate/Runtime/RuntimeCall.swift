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

public protocol StaticRuntimeCall<TReturn>: RuntimeCall, FrameType {
    static var api: String { get }
    static var method: String { get }
}

public extension StaticRuntimeCall {
    @inlinable var method: String { Self.method }
    @inlinable var api: String { Self.api }
    @inlinable var frame: String { api }
    @inlinable static var frame: String { api }
    @inlinable var name: String { method }
    @inlinable static var name: String { method }
    @inlinable static var frameTypeName: String { "RuntimeCall" }
}

public typealias RuntimeCallTypeInfo = (params: [(name: String, type: NetworkType.Info)],
                                        result: NetworkType.Info)
public typealias RuntimeCallChildTypes = (params: [StaticValidatableType.Type],
                                          result: StaticValidatableType.Type)

public extension StaticRuntimeCall where
    Self: ComplexFrameType, TypeInfo == RuntimeCallTypeInfo
{
    @inlinable
    static func typeInfo(runtime: any Runtime) -> Result<TypeInfo, FrameTypeError> {
        guard let info = runtime.resolve(runtimeCall: method, api: api) else {
            return .failure(.typeInfoNotFound(for: Self.self))
        }
        return .success(info)
    }
}

public extension ComplexStaticFrameType where
    TypeInfo == RuntimeCallTypeInfo,
    ChildTypes == RuntimeCallChildTypes
{
    static func validate(info: TypeInfo,
                         runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        let ourTypes = childTypes
        guard ourTypes.params.count == info.params.count else {
            return .failure(.wrongFieldsCount(for: Self.self, expected: ourTypes.params.count,
                                              got: info.params.count))
        }
        return zip(ourTypes.params, info.params).enumerated().voidErrorMap { index, zip in
            let (our, info) = zip
            return our.validate(runtime: runtime, type: info.type).mapError {
                .childError(for: Self.self, index: index, error: $0)
            }
        }.flatMap {
            ourTypes.result.validate(runtime: runtime, type: info.result).mapError {
                .childError(for: Self.self, index: -1, error: $0)
            }
        }
    }
}

public extension StaticRuntimeCall where TReturn: RuntimeDecodable {
    func decode<D: ScaleCodec.Decoder>(returnFrom decoder: inout D, runtime: Runtime) throws -> TReturn {
        try TReturn(from: &decoder, runtime: runtime)
    }
}

public protocol StaticCodableRuntimeCall<TReturn>: StaticRuntimeCall
    where TReturn: ScaleCodec.Decodable
{
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
                              expected: [(String, NetworkType.Info)])
    case parameterNotFound(name: String, inParams: [String: any ValueRepresentable])
}
