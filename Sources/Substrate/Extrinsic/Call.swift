//
//  Call.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public protocol Call: RuntimeEncodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol StaticCall: Call, RuntimeDecodable {
    static var pallet: String { get }
    static var name: String { get }
    
    init<D: ScaleCodec.Decoder>(decodingParams decoder: inout D, runtime: Runtime) throws
    func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
}

public extension StaticCall {
    var pallet: String { Self.pallet }
    var name: String { Self.name }
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let callIndex = try decoder.decode(UInt8.self)
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
        try encoder.encode(info.pallet)
        try encoder.encode(info.index)
        try encodeParams(in: &encoder, runtime: runtime)
    }
}

public struct AnyCall<C>: Call {
    public let pallet: String
    public let name: String
    
    public let params: Value<C>
    
    public init(name: String, pallet: String, params: Value<C>) {
        self.pallet = pallet
        self.name = name
        self.params = params
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        var variant: Value<C>
        switch params.value {
        case .variant(let val):
            guard val.name == self.name else {
                throw CallCodingError.foundWrongCall(found: (name: val.name, pallet: pallet),
                                                     expected: (name: self.name, pallet: pallet))
            }
            variant = params
        case .map(let fields):
            variant = Value(value: .variant(.map(name: name, fields: fields)),
                            context: params.context)
        case .sequence(let vals):
            variant = Value(value: .variant(.sequence(name: name, values: vals)),
                            context: params.context)
        default:
            variant = Value(value: .variant(.sequence(name: name, values: [params])),
                            context: params.context)
        }
        try Value(value: .variant(.sequence(name: pallet, values: [variant])),
                  context: params.context)
            .encode(in: &encoder, as: runtime.types.call.id, runtime: runtime)
    }
}

public extension AnyCall where C == Void {
    init(name: String, pallet: String) {
        self.init(name: name, pallet: pallet, params: .nil)
    }
    
    init(name: String, pallet: String, param: any ValueRepresentable) throws {
        try self.init(name: name, pallet: pallet, params: param.asValue())
    }
    
    init(name: String, pallet: String, from: any ValueMapRepresentable) throws {
        try self.init(name: name, pallet: pallet, params: .map(from: from))
    }
    
    init(name: String, pallet: String, from: any ValueArrayRepresentable) throws {
        try self.init(name: name, pallet: pallet, params: .sequence(from: from))
    }
    
    init(name: String, pallet: String, map: [String: any ValueRepresentable]) throws {
        try self.init(name: name, pallet: pallet, params: .map(map))
    }
    
    init(name: String, pallet: String, sequence: [any ValueRepresentable]) throws {
        try self.init(name: name, pallet: pallet, params: .sequence(sequence))
    }
    
    
}

extension AnyCall: CustomStringConvertible {
    public var description: String {
        "\(pallet).\(name)(\(params))"
    }
}

extension AnyCall: RuntimeDecodable where C == RuntimeTypeId {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        var value = try Value(from: &decoder, as: runtime.types.call.id, runtime: runtime)
        let pallet: String
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            guard values.count == 1 else {
                throw CallCodingError.tooManyFieldsInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw CallCodingError.tooManyFieldsInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = fields.values.first!
        default: throw CallCodingError.decodedNonVariantValue(value)
        }
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .sequence(values), context: value.context))
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .map(fields), context: value.context))
        default: throw CallCodingError.decodedNonVariantValue(value)
        }
    }
}

public enum CallCodingError: Error {
    case callNotFound(index: UInt8, pallet: UInt8)
    case callNotFound(name: String, pallet: String)
    case foundWrongCall(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case tooManyFieldsInVariant(variant: Value<RuntimeTypeId>, expected: Int)
    case decodedNonVariantValue(Value<RuntimeTypeId>)
}
