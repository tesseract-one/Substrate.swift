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

public extension Call {
    @inlinable static var palletTypeName: String { "Call" }
}

public protocol IdentifiableCall: Call, PalletType {}

public protocol SomeBatchCall: IdentifiableCall, RuntimeValidatable {
    var calls: [any Call] { get }
    init(calls: [any Call])
    func add(_ call: any Call) -> Self
}

public protocol StaticCall: IdentifiableCall, RuntimeEncodable, RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(decodingParams decoder: inout D, runtime: Runtime) throws
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
}

public extension StaticCall {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(.enumCaseId)
        let callIndex = try decoder.decode(.enumCaseId)
        guard let info = runtime.resolve(callName: callIndex, pallet: modIndex) else {
            throw CallCodingError.callNotFound(index: callIndex, pallet: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw CallCodingError.foundWrongCall(found: (name: info.name, pallet: info.pallet),
                                                 expected: (name: Self.name, pallet: Self.pallet))
        }
        try self.init(decodingParams: &decoder, runtime: runtime)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let info = runtime.resolve(callIndex: name, pallet: pallet) else {
            throw CallCodingError.callNotFound(name: name, pallet: pallet)
        }
        try encoder.encode(info.pallet, .enumCaseId)
        try encoder.encode(info.index, .enumCaseId)
        try encodeParams(in: &encoder, runtime: runtime)
    }
}

public extension IdentifiableCall where Self: RuntimeValidatableComposite {
    static func validatableFieldIds(runtime: any Runtime) -> Result<[NetworkType.Id], ValidationError> {
        guard let info = runtime.resolve(callParams: name, pallet: pallet) else {
            return .failure(.infoNotFound(for: Self.self))
        }
        return .success(info.map{$0.type})
    }
}

public protocol CallHolder<TCall> {
    associatedtype TCall: Call
    
    var call: TCall { get }
}

public enum CallCodingError: Error {
    case callNotFound(index: UInt8, pallet: UInt8)
    case callNotFound(name: String, pallet: String)
    case foundWrongCall(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case valueNotFound(key: String)
    case wrongFieldCountInVariant(variant: Value<NetworkType.Id>, expected: Int)
    case wrongParametersCount(in: AnyCall<Void>, expected: Int)
    case decodedNonVariantValue(Value<NetworkType.Id>)
}

public protocol CallError: Error, RuntimeDynamicValidatable, RuntimeDynamicDecodable,
                           RuntimeDynamicSwiftDecodable {}
public protocol StaticCallError: CallError, RuntimeDecodable, RuntimeSwiftDecodable {}

