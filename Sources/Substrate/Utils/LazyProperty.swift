//
//  LazyProperty.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import JsonRPC

public struct LazyProperty<Value> {
    private let _value: Synced<Either<() -> Value, Value>>
    
    public init(initializer: @escaping () -> Value) {
        self._value = Synced(value: .left(initializer))
    }
    
    public var value: Value {
        _value.sync { value in
            switch value {
            case .right(let val): return val
            case .left(let cb):
                let val = cb()
                value = .right(val)
                return val
            }
        }
    }
}

public struct LazyThrowingProperty<Value> {
    private let _value: Synced<Either<() throws -> Value, Result<Value, Error>>>
    
    public init(initializer: @escaping () throws -> Value) {
        self._value = Synced(value: .left(initializer))
    }
    
    public var value: Value {
        get throws {
            try _value.sync { value in
                switch value {
                case .right(let res): return try res.get()
                case .left(let cb):
                    let val = Result { try cb() }
                    value = .right(val)
                    return try val.get()
                }
            }
        }
    }
}

public actor LazyAsyncProperty<Value> {
    private var _value: Either<() async -> Value, Value>
    
    public init(initializer: @escaping () async -> Value) {
        self._value = .left(initializer)
    }
    
    public var value: Value {
        get async {
            switch _value {
            case .right(let val): return val
            case .left(let cb):
                let val = await cb()
                _value = .right(val)
                return val
            }
        }
    }
}

public actor LazyAsyncThrowingProperty<Value> {
    private var _value: Either<() async throws -> Value, Result<Value, Error>>
    
    public init(initializer: @escaping () async throws -> Value) {
        self._value = .left(initializer)
    }
    
    public var value: Value {
        get async throws {
            switch _value {
            case .right(let res): return try res.get()
            case .left(let cb):
                do {
                    let val = try await cb()
                    _value = .right(.success(val))
                    return val
                } catch {
                    _value = .right(.failure(error))
                    throw error
                }
            }
        }
    }
}
