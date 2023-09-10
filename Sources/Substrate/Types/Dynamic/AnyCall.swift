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
    
    private let _params: [String: ValueRepresentable]
    
    private init(name: String, pallet: String, _params: [String: ValueRepresentable]) {
        self.pallet = pallet
        self.name = name
        self._params = _params
    }
    
    public func asVoid() -> AnyCall<Void> {
        AnyCall<Void>(name: name, pallet: pallet, _params: _params)
    }
    
    public var errorTypeName: String {
        "Call: \(pallet).\(name)"
    }
}

public extension AnyCall where C == Void {
    var params: [String: ValueRepresentable] { _params }
    
    init(name: String, pallet: String) {
        self.init(name: name, pallet: pallet, _params: [:])
    }
    
    init(name: String, pallet: String, param: ValueRepresentable) {
        self.init(name: name, pallet: pallet, params: [param])
    }
    
    init(name: String, pallet: String, params: [ValueRepresentable]) {
        let pairs = params.enumerated().map{(String($0.offset), $0.element)}
        self.init(name: name, pallet: pallet, _params: Dictionary(uniqueKeysWithValues: pairs))
    }
    
    init(name: String, pallet: String, params: [String: ValueRepresentable]) {
        self.init(name: name, pallet: pallet, _params: params)
    }
}

public extension AnyCall where C == TypeDefinition {
    var params: [String: Value<TypeDefinition>] {
        _params as! [String: Value<TypeDefinition>]
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
                throw FrameTypeError.wrongFieldsCount(for: "AnyCall: \(name)._",
                                                      expected: 1, got: values.count,
                                                      .get())
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw FrameTypeError.wrongFieldsCount(for: "AnyCall: \(name)._",
                                                      expected: 1, got: fields.count,
                                                      .get())
            }
            pallet = name
            value = fields.first!.value
        default: throw FrameTypeError.wrongType(for: "AnyCall: _._",
                                                got: call.description,
                                                reason: "Expected Variant", .get())
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
        default: throw FrameTypeError.wrongType(for: "AnyCall: \(pallet)._",
                                                got: call.description,
                                                reason: "Expected Variant", .get())
        }
    }
}

extension AnyCall: RuntimeDecodable, RuntimeDynamicDecodable where C == TypeDefinition {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let pallet = try decoder.decode(UInt8.self)
        guard let call = runtime.resolve(palletCall: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: "AnyCall: _._", index: 0,
                                                  frame: pallet, .get())
        }
        try self.init(pallet: call.pallet,
                      call: Value(from: &decoder, as: call.type, runtime: runtime))
    }
}

extension AnyCall: RuntimeEncodable, RuntimeDynamicEncodable {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
    {
        guard let palletCall = runtime.resolve(palletCall: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: errorTypeName, .get())
        }
        guard case .variant(variants: let calls) = palletCall.type.definition else {
            throw FrameTypeError.wrongType(for: errorTypeName,
                                           got: palletCall.type.description,
                                           reason: "Expected Variant", .get())
        }
        guard let call = calls.first(where: {$0.name == name}) else {
            throw FrameTypeError.typeInfoNotFound(for: errorTypeName, .get())
        }
        guard call.fields.count == _params.count else {
            throw FrameTypeError.wrongFieldsCount(for: errorTypeName,
                                                  expected: call.fields.count,
                                                  got: _params.count, .get())
        }
        let variant: Value<TypeDefinition>
        if call.fields.first?.name != nil { // Map
            let pairs = try call.fields.enumerated().map { (idx, el) in
                let value: any ValueRepresentable
                if let val = _params[el.name!] {
                    value = val
                } else if let val = _params[String(idx)] {
                    value = val
                } else {
                    throw FrameTypeError.valueNotFound(for: errorTypeName,
                                                       key: el.name!, .get())
                }
                return try (el.name!, value.asValue(of: *el.type, in: runtime))
            }
            let map = Dictionary(uniqueKeysWithValues: pairs)
            variant = Value(value: .variant(.map(name: name, fields: map)),
                            context: palletCall.type)
        } else { // Sequence
            let values = try call.fields.enumerated().map { (idx, el) in
                guard let value = _params[String(idx)] else {
                    throw FrameTypeError.valueNotFound(for: errorTypeName,
                                                       key: String(idx), .get())
                }
                return try value.asValue(of: *el.type, in: runtime)
            }
            variant = Value(value: .variant(.sequence(name: name, values: values)),
                            context: palletCall.type)
        }
        try encoder.encode(palletCall.pallet)
        try variant.encode(in: &encoder, runtime: runtime)
    }
}

extension AnyCall: RuntimeValidatableType {
    @inlinable public var frame: String { pallet }
    
    public func validate(runtime: any Runtime) -> Result<Void, FrameTypeError> {
        guard let callParams = runtime.resolve(callParams: name, pallet: pallet) else {
            return .failure(.typeInfoNotFound(for: errorTypeName, .get()))
        }
        return validate(params: callParams,
                        runtime: runtime).mapError { $0.frameError(for: errorTypeName,
                                                                   .get()) }
    }
}

extension AnyCall: ValidatableTypeDynamic {
    public func validate(as type: TypeDefinition, in runtime: any Runtime) -> Result<Void, TypeError> {
        guard case .variant(let allCalls) = type.flatten().definition else{
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Expected Variant", .get()))
        }
        guard let pallet = allCalls.first(where: { $0.name == pallet }) else {
            return .failure(.variantNotFound(for: Self.self, variant: pallet,
                                             type: type, .get()))
        }
        guard pallet.fields.count == 1 else {
            return .failure(.wrongVariantFieldsCount(for: Self.self,
                                                     variant: pallet.name,
                                                     expected: 1, type: type, .get()))
        }
        guard case .variant(let calls) = pallet.fields[0].type.definition else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Expected Variant", .get()))
        }
        guard let call = calls.first(where: { $0.name == name }) else {
            return .failure(.variantNotFound(for: Self.self,
                                             variant: name, type: type, .get()))
        }
        return validate(params: call.fields,
                        runtime: runtime).mapError { $0.typeError(for: Self.self,
                                                                  type: type, .get()) }
    }
}

extension AnyCall: ValidatableTypeStatic {
    public static func validate(as type: TypeDefinition,
                                in: any Runtime) -> Result<Void, TypeError>
    {
        guard case .variant(variants: let vars) = type.definition else {
            return .failure(.wrongType(for: Self.self,
                                       type: type,
                                       reason: "Isn't variant", .get()))
        }
        return vars.voidErrorMap { vart in
            guard vart.fields.count == 1 else {
                return .failure(.wrongVariantFieldsCount(for: Self.self,
                                                         variant: vart.name,
                                                         expected: 1, type: type, .get()))
            }
            guard case .variant(_) = vart.fields[0].type.definition else {
                return .failure(.wrongType(for: Self.self,
                                           type: *vart.fields[0].type,
                                           reason: "Child type isn't variant", .get()))
            }
            return .success(())
        }
    }
}

extension AnyCall: CustomStringConvertible {
    public var description: String {
        "\(pallet).\(name)(\(_params))"
    }
}

private extension AnyCall {
    enum ParamsError: Error {
        case valueNotFound(key: String)
        case wrongFieldsCount(expected: Int, got: Int)
        case childError(index: Int, error: TypeError)
        
        func frameError(for t: String, _ info: ErrorMethodInfo) -> FrameTypeError {
            switch self {
            case .valueNotFound(key: let k):
                return .valueNotFound(for: t, key: k, info)
            case .wrongFieldsCount(expected: let e, got: let g):
                return .wrongFieldsCount(for: t, expected: e, got: g, info)
            case .childError(index: let i, error: let e):
                return .childError(for: t, index: i, error: e, info)
            }
        }
        
        func typeError(for t: Any.Type, type: TypeDefinition,
                       _ einfo: ErrorMethodInfo) -> TypeError
        {
            switch self {
            case .valueNotFound(key: let k):
                return .fieldNotFound(for: t, field: k, type: type, einfo)
            case .wrongFieldsCount(expected: _, got: let g): // Inverted
                return .wrongValuesCount(for: t, expected: g, type: type, einfo)
            case .childError(index: _, error: let e): return e
            }
        }
    }
    
    func validate(params: [TypeDefinition.Field],
                  runtime: any Runtime) -> Result<Void, ParamsError>
    {
        guard params.count == _params.count else {
            return .failure(.wrongFieldsCount(expected: params.count,
                                              got: _params.count))
        }
        return params.enumerated().voidErrorMap { (idx, param) in
            let key: String
            let value: ValueRepresentable?
            if let name = param.name {
                if let val = _params[name] {
                    key = name
                    value = val
                } else {
                    key = String(idx)
                    value = nil
                }
            } else {
                key = String(idx)
                value = nil
            }
            guard let val = (value ?? _params[key]) else {
                return .failure(.valueNotFound(key: key))
            }
            return val.validate(as: *param.type, in: runtime).mapError {
                .childError(index: idx, error: $0)
            }
        }
    }
}
