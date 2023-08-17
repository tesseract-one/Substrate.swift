//
//  AnyCallErrors.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyDispatchError: CallError, CustomStringConvertible {
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
        "DispatchError: \(value)"
    }
}

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
