//
//  Call.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol Call: RuntimeDynamicEncodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol PalletCall: Call, FrameType {
    static var pallet: String { get }
}

public extension PalletCall {
    @inlinable var pallet: String { Self.pallet }
    @inlinable var frame: String { pallet }
    @inlinable static var frameTypeName: String { "Call" }
    @inlinable static var frame: String { pallet }
}

public typealias CallTypeInfo = [(field: NetworkType.Field, type: NetworkType)]
public typealias CallChildTypes = [ValidatableType.Type]

public extension PalletCall where
    Self: ComplexFrameType, TypeInfo == CallTypeInfo
{
    static func typeInfo(runtime: any Runtime) -> Result<TypeInfo, FrameTypeError> {
        guard let info = runtime.resolve(callParams: name, pallet: pallet) else {
            return .failure(.typeInfoNotFound(for: Self.self))
        }
        return .success(info)
    }
}

public protocol SomeBatchCall: PalletCall {
    var calls: [any Call] { get }
    init(calls: [any Call])
    func add(_ call: any Call) -> Self
}

public protocol StaticCall: PalletCall, RuntimeEncodable, RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(decodingParams decoder: inout D, runtime: Runtime) throws
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
}

public extension StaticCall {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(.enumCaseId)
        let callIndex = try decoder.decode(.enumCaseId)
        guard let info = runtime.resolve(callName: callIndex, pallet: modIndex) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, index: callIndex, frame: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw FrameTypeError.foundWrongType(for: Self.self, name: info.name, frame: info.pallet)
        }
        try self.init(decodingParams: &decoder, runtime: runtime)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let info = runtime.resolve(callIndex: name, pallet: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self)
        }
        try encoder.encode(info.pallet, .enumCaseId)
        try encoder.encode(info.index, .enumCaseId)
        try encodeParams(in: &encoder, runtime: runtime)
    }
}

public protocol CallHolder<TCall> {
    associatedtype TCall: Call
    
    var call: TCall { get }
}

public protocol CallError: Error, ValidatableType, RuntimeDynamicDecodable,
                           RuntimeDynamicSwiftDecodable {}
public protocol StaticCallError: CallError, RuntimeDecodable, RuntimeSwiftDecodable, IdentifiableType {}

