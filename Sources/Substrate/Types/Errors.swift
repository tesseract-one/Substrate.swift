//
//  Errors.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation

public struct AnyDispatchError: DynamicApiError, CustomStringConvertible {
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<RuntimeType.Id>
    
    public init(value: Value<RuntimeType.Id>, runtime: any Runtime) throws {
        self.value = value
    }
    
    public var description: String {
        "DispatchError: \(value)"
    }
}

public struct AnyTransactionValidityError: DynamicApiError, CustomStringConvertible {
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    
    public let value: Value<RuntimeType.Id>
    
    public init(value: Value<RuntimeType.Id>, runtime: any Runtime) throws {
        self.value = value
    }
    
    public var description: String {
        "TransactionValidityError: \(value)"
    }
}
