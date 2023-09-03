//
//  AnyCall.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

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
                                              as type: NetworkType.Id,
                                              runtime: Runtime) throws
    {
        guard let callParams = runtime.resolve(callParams: name, pallet: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: errorTypeName)
        }
        guard callParams.count == _params.count else {
            throw FrameTypeError.wrongFieldsCount(for: errorTypeName,
                                                  expected: callParams.count,
                                                  got: _params.count)
        }
        let variant: Value<NetworkType.Id>
        if callParams.first?.field.name != nil { // Map
            let pairs = try callParams.enumerated().map { (idx, el) in
                let value: any ValueRepresentable
                if let val = _params[el.field.name!] {
                    value = val
                } else if let val = _params[String(idx)] {
                    value = val
                } else {
                    throw FrameTypeError.valueNotFound(for: errorTypeName, key:el.field.name!)
                }
                return try (el.field.name!, value.asValue(runtime: runtime, type: el.field.type))
            }
            let map = Dictionary(uniqueKeysWithValues: pairs)
            variant = Value(value: .variant(.map(name: name, fields: map)), context: type)
        } else { // Sequence
            let values = try callParams.enumerated().map { (idx, el) in
                guard let value = _params[String(idx)] else {
                    throw FrameTypeError.valueNotFound(for: errorTypeName, key: String(idx))
                }
                return try value.asValue(runtime: runtime, type: el.field.type)
            }
            variant = Value(value: .variant(.sequence(name: name, values: values)), context: type)
        }
        try Value(value: .variant(.sequence(name: pallet, values: [variant])),
                  context: type).encode(in: &encoder, as: type, runtime: runtime)
    }
    
    public func asVoid() -> AnyCall<Void> {
        AnyCall<Void>(name: name, pallet: pallet, _params: _params)
    }
    
    public var errorTypeName: String {
        "Call: \(pallet).\(name)"
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

extension AnyCall: ValidatableType {
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        return Result { try runtime.types.call }
            .mapError { .runtimeTypeLookupFailed(for: Self.self, type: "call", reason: $0) }
            .flatMap {
                $0.type == type.type ? .success(()) :
                    .failure(.wrongType(for: Self.self, got: type.type,
                                        reason: "call types is different"))
            }
    }
}

extension AnyCall: CustomStringConvertible {
    public var description: String {
        "\(pallet).\(name)(\(_params))"
    }
}

public extension AnyCall where C == NetworkType.Id {
    var params: [String: Value<NetworkType.Id>] {
        _params as! [String: Value<NetworkType.Id>]
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
                throw FrameTypeError.wrongFieldsCount(for: "AnyCall",
                                                      expected: 1, got: values.count)
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw FrameTypeError.wrongFieldsCount(for: "AnyCall",
                                                      expected: 1, got: fields.count)
            }
            pallet = name
            value = fields.first!.value
        default: throw FrameTypeError.paramMismatch(for: "AnyCall",
                                                    index: 0,
                                                    expected: "Value.Variant",
                                                    got: call.description)
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
        default: throw FrameTypeError.paramMismatch(for: "AnyCall: \(pallet)",
                                                    index: 0,
                                                    expected: "Value.Variant",
                                                    got: call.description)
        }
    }
}

extension AnyCall: RuntimeDynamicDecodable where C == NetworkType.Id {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: NetworkType.Id,
                                       runtime: Runtime) throws
    {
        try self.init(root: Value(from: &decoder, as: type, runtime: runtime))
    }
}
