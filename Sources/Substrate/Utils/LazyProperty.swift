//
//  LazyProperty.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import JsonRPC

public struct LazyProperty<Value> {
    private let _initializer: () throws -> Value
    private let _value: Synced<Value?>
    
    public init(initializer: @escaping () throws -> Value) {
        self._initializer = initializer
        self._value = Synced(value: nil)
    }
    
    public var value: Value {
        get throws {
            try _value.sync { value in
                if let value = value { return value }
                value = try self._initializer()
                return value!
            }
        }
    }
}

public actor LazyAsyncProperty<Value> {
    private let _initializer: () async throws -> Value
    private var _value: Value?
    
    public init(initializer: @escaping () async throws -> Value) {
        self._initializer = initializer
        self._value = nil
    }
    
    public var value: Value {
        get async throws {
            if let value = _value { return value }
            _value = try await _initializer()
            return _value!
        }
    }
}
