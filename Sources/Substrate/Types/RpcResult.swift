//
//  RpcResult.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public enum RpcResult<T, E> {
    case ok(T)
    case err(E)
    
    var isErr: Bool {
        switch self {
        case .err(_): return true
        default: return false
        }
    }
    
    var isOk: Bool { !isErr }
    
    var value: T? {
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

extension RpcResult: Encodable where T: Encodable, E: Encodable {
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

extension RpcResult: Decodable where T: Decodable, E: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        if container.contains(.ok) {
            self = try .ok(container.decode(T.self, forKey: .ok))
        } else if container.contains(.err) {
            self = try .err(container.decode(E.self, forKey: .err))
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .ok, in: container, debugDescription: "Object doesn't have ok or err values"
            )
        }
    }
}
