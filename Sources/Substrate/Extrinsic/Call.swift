//
//  Call.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol Call: RuntimeEncodable, RuntimeValidatableType {
    var pallet: String { get }
    var name: String { get }
}

public protocol PalletCall: Call, RuntimeDecodable, FrameType {
    static var pallet: String { get }
}

public extension PalletCall {
    @inlinable var pallet: String { Self.pallet }
    @inlinable var frame: String { pallet }
    @inlinable static var frameTypeName: String { "Call" }
    @inlinable static var frame: String { pallet }
}

public typealias CallTypeInfo = [TypeDefinition.Field]
public typealias CallChildTypes = [ValidatableTypeStatic.Type]

public extension PalletCall where
    Self: ComplexFrameType, TypeInfo == CallTypeInfo
{
    static func typeInfo(from runtime: any Runtime) -> Result<TypeInfo, FrameTypeError> {
        guard let info = runtime.resolve(callParams: name, pallet: pallet) else {
            return .failure(.typeInfoNotFound(for: Self.self, .get()))
        }
        return .success(info)
    }
}

public protocol SomeBatchCall: PalletCall {
    var calls: [any Call] { get }
    init(calls: [any Call])
    func add(_ call: any Call) -> Self
}

public protocol StaticCall: PalletCall {
    init<D: ScaleCodec.Decoder>(decodingParams decoder: inout D, runtime: Runtime) throws
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
}

public extension StaticCall {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(.enumCaseId)
        let callIndex = try decoder.decode(.enumCaseId)
        guard let info = runtime.resolve(callName: callIndex, pallet: modIndex) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, index: callIndex,
                                                  frame: modIndex, .get())
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw FrameTypeError.foundWrongType(for: Self.self, name: info.name,
                                                frame: info.pallet, .get())
        }
        try self.init(decodingParams: &decoder, runtime: runtime)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let info = runtime.resolve(callIndex: name, pallet: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, .get())
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

public protocol CallError: Error, ValidatableType, RuntimeLazyDynamicDecodable,
                           RuntimeLazyDynamicSwiftDecodable {}
public protocol StaticCallError: CallError, RuntimeDecodable, RuntimeSwiftDecodable, IdentifiableType {}

