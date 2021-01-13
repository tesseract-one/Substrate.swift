//
//  Type.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public indirect enum DType: Equatable, Hashable, Encodable {
    case null
    case doNotConstruct(type: DType)
    case type(name: String)
    case compact(type: DType)
    case collection(element: DType)
    case fixed(type: DType, count: Int)
    case optional(element: DType)
    case map(key: DType, value: DType)
    case result(success: DType, error: DType)
    case tuple(elements: [DType])
    
    var name: String {
        switch self {
        case .null: return "Null"
        case .doNotConstruct: return "DoNotConstruct"
        case .type(name: let name): return name
        case .compact(type: _): return "Compact"
        case .collection(element: _): return "Array"
        case .fixed(type: _, count: let count): return "[\(count)]"
        case .optional(element: _): return "Optional"
        case .map(key: _, value: _): return "Dictionary"
        case .tuple(elements: let types): return "(\(types.count))"
        case .result(success: _, error: _): return "Result"
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension DType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: return "Null"
        case .doNotConstruct(let t): return "DoNotConstruct<\(t)>"
        case .type(name: let name): return name
        case .compact(type: let type): return "Compact<\(type)>"
        case .collection(element: let element): return "Array<\(element)>"
        case .fixed(type: let type, count: let count): return "[\(type); \(count)]"
        case .optional(element: let type): return "Optional<\(type)>"
        case .result(success: let stype, error: let etype): return "Result<\(stype), \(etype)>"
        case .map(key: let key, value: let value): return "Dictionary<\(key), \(value)>"
        case .tuple(elements: let types):
            let joined = types.map { "\($0)" }.joined(separator: ", ")
            return "(\(joined))"
        }
    }
}

extension DType: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}
