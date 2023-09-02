//
//  AnyCallErrors.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyTransactionValidityError: CallError, CustomStringConvertible {
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<NetworkType.Id>
    
    public init(value: Value<NetworkType.Id>) {
        self.value = value
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: NetworkType.Id, runtime: Runtime) throws {
        let value = try Value<NetworkType.Id>(from: &decoder, as: type, runtime: runtime)
        self.init(value: value)
    }
    
    public init(from decoder: Swift.Decoder, as type: NetworkType.Id, runtime: Runtime) throws {
        let value = try Value<NetworkType.Id>(from: decoder, as: type, runtime: runtime)
        self.init(value: value)
    }
    
    public static func validate(runtime: Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError> {
        .success(())
    }
    
    public var description: String {
        "TransactionValidityError: \(value)"
    }
}

public struct AnyDispatchError: SomeDispatchError, CustomStringConvertible {
    public typealias TModuleError = ModuleError
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<NetworkType.Id>
    private let _runtime: any Runtime
    
    @inlinable
    public var isModuleError: Bool { value.variant?.name.contains("Module") ?? false }
    
    public var moduleError: TModuleError { get throws {
        let variant = value.variant!
        guard variant.name.contains("Module") else {
            throw ModuleError.DecodingError.dispatchErrorIsNotModule(description: description)
        }
        return try ModuleError(variant: variant, runtime: _runtime)
    }}
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: NetworkType.Id, runtime: Runtime) throws {
        let value = try Value<NetworkType.Id>(from: &decoder, as: type, runtime: runtime)
        guard value.variant != nil else {
            throw ScaleCodec.DecodingError.typeMismatch(
                Value<NetworkType.Id>.self,
                .init(path: decoder.path, description: "Decoded non-variant value")
            )
        }
        self.value = value
        self._runtime = runtime
    }
    
    public init(from decoder: Swift.Decoder, as type: NetworkType.Id, runtime: Runtime) throws {
        let value = try Value<NetworkType.Id>(from: decoder, as: type, runtime: runtime)
        guard value.variant != nil else {
            throw Swift.DecodingError.typeMismatch(
                Value<NetworkType.Id>.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Decoded non-variant value")
            )
        }
        self.value = value
        self._runtime = runtime
    }
    
    public static func validate(runtime: Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        guard case .variant(variants: let vars) = info.definition else {
            return .failure(.wrongType(got: info, for: "DispatchError"))
        }
        guard let module = vars.first(where: { $0.name.contains("Module") }) else {
            return .failure(.variantNotFound(name: "Module", in: info))
        }
        guard TModuleError.validate(variant: module, runtime: runtime) else {
            return .failure(.wrongType(got: info, for: "DispatchError.Module"))
        }
        return .success(())
    }
    
    public var description: String {
        "DispatchError: \(value)"
    }
}
