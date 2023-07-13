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

public protocol IdentifiableCall: Call, RuntimeDynamicDecodable {
    static var pallet: String { get }
    static var name: String { get }
}

public extension IdentifiableCall {
    var pallet: String { Self.pallet }
    var name: String { Self.name }
}

public protocol StaticCall: IdentifiableCall, RuntimeEncodable, RuntimeDecodable {
    static var pallet: String { get }
    static var name: String { get }
    
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

public struct AnyCall<C>: Call {
    public let pallet: String
    public let name: String
    
    private let _params: [String: any ValueRepresentable]
    
    private init(name: String, pallet: String, _params: [String: any ValueRepresentable]) {
        self.pallet = pallet
        self.name = name
        self._params = _params
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                              as type: RuntimeType.Id,
                                              runtime: Runtime) throws
    {
        guard let callParams = runtime.resolve(callParams: name, pallet: pallet) else {
            throw CallCodingError.callNotFound(name: name, pallet: pallet)
        }
        guard callParams.count == _params.count else {
            throw CallCodingError.wrongParametersCount(in: asVoid(), expected: callParams.count)
        }
        let variant: Value<RuntimeType.Id>
        if callParams.first?.name != nil { // Map
            let pairs = try callParams.enumerated().map { (idx, el) in
                let value: any ValueRepresentable
                if let val = _params[el.name!] {
                    value = val
                } else if let val = _params[String(idx)] {
                    value = val
                } else {
                    throw CallCodingError.valueNotFound(key: el.name!)
                }
                return try (el.name!, value.asValue(runtime: runtime, type: el.type))
            }
            let map = Dictionary(uniqueKeysWithValues: pairs)
            variant = Value(value: .variant(.map(name: name, fields: map)), context: type)
        } else { // Sequence
            let values = try callParams.enumerated().map { (idx, el) in
                guard let value = _params[String(idx)] else {
                    throw CallCodingError.valueNotFound(key: String(idx))
                }
                return try value.asValue(runtime: runtime, type: el.type)
            }
            variant = Value(value: .variant(.sequence(name: name, values: values)), context: type)
        }
        try Value(value: .variant(.sequence(name: pallet, values: [variant])),
                  context: type).encode(in: &encoder, as: type, runtime: runtime)
    }
    
    public func asVoid() -> AnyCall<Void> {
        AnyCall<Void>(name: name, pallet: pallet, _params: _params)
    }
}

public extension AnyCall where C == Void {
    var params: [String: any ValueRepresentable] { _params }
    
    init(name: String, pallet: String) {
        self.init(name: name, pallet: pallet, _params: [:])
    }
    
    init(name: String, pallet: String, param: any ValueRepresentable) {
        self.init(name: name, pallet: pallet, params: [param])
    }
    
    init(name: String, pallet: String, params: [any ValueRepresentable]) {
        let pairs = params.enumerated().map{(String($0.offset), $0.element)}
        self.init(name: name, pallet: pallet, _params: Dictionary(uniqueKeysWithValues: pairs))
    }
    
    init(name: String, pallet: String, params: [String: any ValueRepresentable]) {
        self.init(name: name, pallet: pallet, _params: params)
    }
}

extension AnyCall: CustomStringConvertible {
    public var description: String {
        "\(pallet).\(name)(\(_params))"
    }
}

public extension AnyCall where C == RuntimeType.Id {
    var params: [String: Value<RuntimeType.Id>] {
        _params as! [String: Value<RuntimeType.Id>]
    }
    
    init(name: String, pallet: String) {
        self.init(name: name, pallet: pallet, _params: [:])
    }
    
    init(name: String, pallet: String, param: Value<C>) {
        self.init(name: name, pallet: pallet, params: [param])
    }
    
    init(name: String, pallet: String, params: [Value<C>]) {
        let pairs = params.enumerated().map{(String($0.offset), $0.element)}
        self.init(name: name, pallet: pallet, _params: Dictionary(uniqueKeysWithValues: pairs))
    }
    
    init(name: String, pallet: String, params: [String: Value<C>]) {
        self.init(name: name, pallet: pallet, _params: params)
    }
    
    init(root call: Value<C>) throws {
        var value = call
        let pallet: String
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            guard values.count == 1 else {
                throw CallCodingError.wrongFieldCountInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw CallCodingError.wrongFieldCountInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = fields.values.first!
        default: throw CallCodingError.decodedNonVariantValue(value)
        }
        try self.init(pallet: pallet, call: value)
    }
    
    init(pallet: String, call: Value<C>) throws {
        switch call.value {
        case .variant(.sequence(name: let name, values: let values)):
            let fields = values.enumerated().map{(String($0.offset), $0.element)}
            self.init(name: name,
                      pallet: pallet,
                      params: Dictionary(uniqueKeysWithValues: fields))
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: fields)
        default: throw CallCodingError.decodedNonVariantValue(call)
        }
    }
}

extension AnyCall: RuntimeDynamicDecodable where C == RuntimeType.Id {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        try self.init(root: Value(from: &decoder, as: type, runtime: runtime))
    }
}

public enum CallCodingError: Error {
    case callNotFound(index: UInt8, pallet: UInt8)
    case callNotFound(name: String, pallet: String)
    case foundWrongCall(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case valueNotFound(key: String)
    case wrongFieldCountInVariant(variant: Value<RuntimeType.Id>, expected: Int)
    case wrongParametersCount(in: AnyCall<Void>, expected: Int)
    case decodedNonVariantValue(Value<RuntimeType.Id>)
}
