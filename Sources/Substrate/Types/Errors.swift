//
//  Errors.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation

public struct AnyDispatchError: DynamicApiError, CustomStringConvertible {
    public let value: Value<RuntimeTypeId>
    
    public static func errorType(runtime: any Runtime) throws -> RuntimeTypeInfo {
        try runtime.types.dispatchError
    }
    
    public init(value: Value<RuntimeTypeId>) throws {
        self.value = value
    }
    
    public var description: String {
        "DispatchError: \(value)"
    }
}

public struct AnyTransactionValidityError: DynamicApiError, CustomStringConvertible {
    public let value: Value<RuntimeTypeId>
    
    public static func errorType(runtime: any Runtime) throws -> RuntimeTypeInfo {
        try runtime.types.transactionValidityError
    }
    
    public init(value: Value<RuntimeTypeId>) throws {
        self.value = value
    }
    
    public var description: String {
        "TransactionValidityError: \(value)"
    }
}
