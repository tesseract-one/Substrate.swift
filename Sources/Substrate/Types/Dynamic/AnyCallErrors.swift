//
//  AnyCallErrors.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyTransactionValidityError: CallError, CustomDebugStringConvertible {
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<TypeDefinition>
    
    public init(value: Value<TypeDefinition>) {
        self.value = value
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: TypeDefinition, runtime: Runtime) throws {
        let value = try Value<TypeDefinition>(from: &decoder, as: type, runtime: runtime)
        self.init(value: value)
    }
    
    public init(from decoder: Swift.Decoder, as type: TypeDefinition, runtime: Runtime) throws {
        let value = try Value<TypeDefinition>(from: decoder, as: type, runtime: runtime)
        self.init(value: value)
    }
    
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        Value<TypeDefinition>.validate(as: type, in: runtime)
    }
    
    public var debugDescription: String {
        "TransactionValidityError: \(value)"
    }
}

public struct AnyDispatchError: SomeDispatchError, VariantValidatableType, CustomDebugStringConvertible {
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<TypeDefinition>
    private let _runtime: any Runtime
    
    @inlinable
    public var isModuleError: Bool { value.variant?.name == "Module" }
    
    public var moduleErrorInfo: (name: String, pallet: String) { get throws {
        let data = try moduleErrorData
        let info = try AnyModuleError.fetchInfo(error: data[1],
                                                pallet: data[0],
                                                runtime: _runtime).get()
        return (info.error.name, info.pallet)
    }}
    
    public func typedModuleError<E: PalletError>(_ type: E.Type) throws -> E {
        try _runtime.decode(from: moduleErrorData)
    }
    
    public var moduleError: Value<TypeDefinition> { get throws {
        guard isModuleError else {
            throw FrameTypeError.paramMismatch(for: "AnyDispatchError",
                                               index: -1, expected: "Module",
                                               got: "\(self)", .get())
        }
        let fields = value.variant!.values
        guard fields.count == 1 else {
            throw FrameTypeError.wrongFieldsCount(for: "DispatchError.Module",
                                                  expected: 1, got: fields.count, .get())
        }
        return fields[0]
    }}
    
    public var moduleErrorData: Data { get throws {
        try _runtime.encode(value: moduleError)
    }}
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: TypeDefinition, runtime: Runtime) throws {
        let value = try Value<TypeDefinition>(from: &decoder, as: type, runtime: runtime)
        guard value.variant != nil else {
            throw ScaleCodec.DecodingError.typeMismatch(
                Value<TypeDefinition>.self,
                .init(path: decoder.path, description: "Decoded non-variant value")
            )
        }
        self.value = value
        self._runtime = runtime
    }
    
    public init(from decoder: Swift.Decoder, as type: TypeDefinition, runtime: Runtime) throws {
        let value = try Value<TypeDefinition>(from: decoder, as: type, runtime: runtime)
        guard value.variant != nil else {
            throw Swift.DecodingError.typeMismatch(
                Value<TypeDefinition>.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Decoded non-variant value")
            )
        }
        self.value = value
        self._runtime = runtime
    }
    
    public static func validate(info: TypeInfo, as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard let module = info.first(where: { $0.name.contains("Module") }) else {
            return .failure(.variantNotFound(for: Self.self,
                                             variant: "*Module*",
                                             type: type, .get()))
        }
        guard module.fields.count == 1 else {
            return .failure(.wrongValuesCount(for: Self.self, expected: 1,
                                              type: type, .get()))
        }
        return .success(())
    }
    
    public var debugDescription: String {
        "DispatchError: \(value)"
    }
}
