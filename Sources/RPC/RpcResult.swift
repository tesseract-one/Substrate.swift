//
//  RpcResult.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation
import ContextCodable

public enum RpcResult<V, E> {
    case ok(V)
    case err(E)
    
    var isErr: Bool {
        switch self {
        case .err(_): return true
        default: return false
        }
    }
    
    var isOk: Bool { !isErr }
    
    var value: V? {
        switch self {
        case .ok(let val): return val
        default: return nil
        }
    }
    
    var error: E? {
        switch self {
        case .err(let err): return err
        default: return nil
        }
    }
    
    private enum Keys: String, CodingKey {
        case ok = "Ok"
        case err = "Err"
    }
}

extension RpcResult where E: Error {
    public func get() throws -> V {
        switch self {
        case .ok(let val): return val
        case .err(let error): throw error
        }
    }
}

extension RpcResult: Encodable where V: Encodable, E: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .ok(let val):
            try container.encode(val, forKey: .ok)
        case .err(let val):
            try container.encode(val, forKey: .err)
        }
    }
}

extension RpcResult: ContextEncodable where V: ContextEncodable, E: ContextEncodable {
    public typealias EncodingContext = (value: V.EncodingContext, error: E.EncodingContext)
    public func encode(to encoder: Encoder, context: EncodingContext) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .ok(let val):
            try container.encode(val, forKey: .ok, context: context.value)
        case .err(let val):
            try container.encode(val, forKey: .err, context: context.error)
        }
    }
}

extension RpcResult: Decodable where V: Decodable, E: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        if container.contains(.ok) {
            self = try .ok(container.decode(V.self, forKey: .ok))
        } else if container.contains(.err) {
            self = try .err(container.decode(E.self, forKey: .err))
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .ok, in: container, debugDescription: "Object doesn't have ok or err values"
            )
        }
    }
}

extension RpcResult: ContextDecodable where V: ContextDecodable, E: ContextDecodable {
    public typealias DecodingContext = (value: V.DecodingContext, error: E.DecodingContext)
    public init(from decoder: Decoder, context: DecodingContext) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        if container.contains(.ok) {
            self = try .ok(container.decode(V.self, forKey: .ok, context: context.value))
        } else if container.contains(.err) {
            self = try .err(container.decode(E.self, forKey: .err, context: context.error))
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .ok, in: container, debugDescription: "Object doesn't have ok or err values"
            )
        }
    }
}
