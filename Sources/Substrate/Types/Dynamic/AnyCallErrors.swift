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
    
    public let value: Value<RuntimeType.Id>
    
    public init(value: Value<RuntimeType.Id>) {
        self.value = value
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: RuntimeType.Id, runtime: Runtime) throws {
        let value = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
        self.init(value: value)
    }
    
    public init(from decoder: Swift.Decoder, as type: RuntimeType.Id, runtime: Runtime) throws {
        let value = try Value<RuntimeType.Id>(from: decoder, as: type, runtime: runtime)
        self.init(value: value)
    }
    
    public var description: String {
        "TransactionValidityError: \(value)"
    }
}

public struct AnyDispatchError: SomeDispatchError, CustomStringConvertible {
    public typealias TModuleError = ModuleError
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<RuntimeType.Id>
    private let _runtime: any Runtime
    
    public init(value: Value<RuntimeType.Id>, runtime: any Runtime) {
        self.value = value
        self._runtime = runtime
    }
    
    @inlinable
    public var isModuleError: Bool { value.variant?.name.contains("Module") ?? false }
    
    public var moduleError: TModuleError { get throws {
        guard let variant = value.variant else {
            throw ModuleError.DecodingError.nonVariantValue(value)
        }
        guard variant.name.contains("Module") else {
            throw ModuleError.DecodingError.dispatchErrorIsNotModule(description: description)
        }
        return try ModuleError(variant: variant, runtime: _runtime)
    }}
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: RuntimeType.Id, runtime: Runtime) throws {
        let value = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
        self.init(value: value, runtime: runtime)
    }
    
    public init(from decoder: Swift.Decoder, as type: RuntimeType.Id, runtime: Runtime) throws {
        let value = try Value<RuntimeType.Id>(from: decoder, as: type, runtime: runtime)
        self.init(value: value, runtime: runtime)
    }
    
    public var description: String {
        "DispatchError: \(value)"
    }
}
