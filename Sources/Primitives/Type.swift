//
//  Type.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public indirect enum SType: Equatable, Hashable {
    case null
    case plain(name: String)
    case collection(name: String, element: SType)
    case fixed(type: SType, count: Int)
    case optional(element: SType)
    case map(name: String, key: SType, value: SType)
    case result(success: SType, error: SType)
    case tuple(elements: [SType])
    
    var name: String {
        switch self {
        case .null: return "Null"
        case .plain(name: let name): return name
        case .collection(name: let name, element: _): return name
        case .fixed(type: _, count: let count): return "[\(count)]"
        case .optional(element: _): return "Option"
        case .map(name: let name, key: _, value: _): return name
        case .tuple(elements: let types): return "(\(types.count))"
        case .result(success: _, error: _): return "Result"
        }
    }
}

extension SType {
    public init(_ string: String) throws {
        self = .plain(name: string)
    }
    
//    func clean
}

extension SType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: return "Null"
        case .plain(name: let name): return name
        case .collection(name: let name, element: let element): return "\(name)<\(element)>"
        case .fixed(type: let type, count: let count): return "[\(type); \(count)]"
        case .optional(element: let type): return "Option<\(type)>"
        case .result(success: let stype, error: let etype): return "Result<\(stype), \(etype)>"
        case .map(name: let name, key: let key, value: let value): return "\(name)<\(key), \(value)>"
        case .tuple(elements: let types):
            let joined = types.map { "\($0)" }.joined(separator: ", ")
            return "(\(joined))"
        }
    }
}

extension SType: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}
