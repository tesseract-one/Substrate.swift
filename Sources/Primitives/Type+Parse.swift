//
//  Type+Parse.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public enum DTypeParsingError: Error {
    case unclosedBracket(in: String)
    case badInteger(string: String)
    case wrongSubtypesCount(count: Int, expected: Int)
    case typeUnallowedCharacter(in: String)
}

extension DType {
    public init(parse: String) throws {
        let cleaned = try DType.cleanup(string: parse)
        switch cleaned {
        case let e where e.hasPrefix("("): try self.init(tuple: e) // Tuple
        case let e where e.hasPrefix("["): // Fixed array or slice
            if let index = e.lastIndex(of: ";") {
                try self.init(fixed: e, index: e.distance(from: e.startIndex, to: index))
            } else {
                try self.init(slice: e, offset: 1)
            }
        case let e where e.hasPrefix("&["): try self.init(slice: e, offset: 2)
        case let e where e.hasPrefix("Vec<"): try self.init(vec: e) // Vec<>
        case let e where e.hasPrefix("Map<"): try self.init(map: e) // Map<>
        case let e where e.hasPrefix("Result<"): try self.init(result: e)
        case let e where e.hasPrefix("DoNotConstruct"): try self.init(doNotConstruct: e)
        case let e where e.hasPrefix("Option<"): try self.init(option: e)
        case let e where e.hasPrefix("Compact<"): try self.init(compact: e)
        case "Null": self = .null
        default: try self.init(primitive: cleaned)
        }
    }
    
    private init(primitive: String) throws {
        guard primitive.rangeOfCharacter(from: Self.primitiveUnallowedCharacters) == nil else {
            throw DTypeParsingError.typeUnallowedCharacter(in: primitive)
        }
        self = .type(name: primitive)
    }
    
    private init(doNotConstruct: String) throws {
        guard doNotConstruct.count > 16 else {
            self = .doNotConstruct(type: .null)
            return
        }
        let type = String(doNotConstruct.substr(from: 15, removing: 1))
        self = try .doNotConstruct(type: DType(parse: type))
    }
    
    private init(tuple: String) throws {
        let end = try Self.findClosingBracket(in: tuple, from: 1, lbr: "(", rbr: ")")
        let typesStr = String(tuple.substr(from: 1, to: end-1))
        let subtypes = try Self.typeSplit(type: typesStr).map { type in
            try DType(parse: type)
        }
        self = .tuple(elements: subtypes)
    }
    
    private init(slice: String, offset: Int) throws {
        let type = String(slice.substr(from: offset, removing: 1))
        self = try .collection(element: DType(parse: type))
    }
    
    private init(fixed: String, index: Int) throws {
        let type = String(fixed.substr(from: 1, to: index-1))
        let cstr = String(fixed.substr(from: index+1, removing: 1)).trimmingCharacters(in: .whitespaces)
        guard let count = Int(cstr) else {
            throw DTypeParsingError.badInteger(string: cstr)
        }
        self = try .fixed(type: DType(parse: type), count: count)
    }
    
    private init(option: String) throws {
        let end = try Self.findClosingBracket(in: option, from: 7, lbr: "<", rbr: ">")
        let type = String(option.substr(from: 7, to: end-1))
        self = try .optional(element: DType(parse: type))
    }
    
    private init(compact: String) throws {
        let end = try Self.findClosingBracket(in: compact, from: 8, lbr: "<", rbr: ">")
        let type = String(compact.substr(from: 8, to: end-1))
        self = try .compact(type: DType(parse: type))
    }
    
    private init(vec: String) throws {
        let end = try Self.findClosingBracket(in: vec, from: 4, lbr: "<", rbr: ">")
        let type = String(vec.substr(from: 4, to: end-1))
        self = try .collection(element: DType(parse: type))
    }
    
    private init(map: String) throws {
        let end = try Self.findClosingBracket(in: map, from: 4, lbr: "<", rbr: ">")
        let typesStr = String(map.substr(from: 4, to: end-1))
        let subtypes = try Self.typeSplit(type: typesStr).map { try DType(parse: $0) }
        guard subtypes.count == 2 else {
            throw DTypeParsingError.wrongSubtypesCount(count: subtypes.count, expected: 2)
        }
        self = .map(key: subtypes[0], value: subtypes[1])
    }
    
    private init(result: String) throws {
        let end = try Self.findClosingBracket(in: result, from: 7, lbr: "<", rbr: ">")
        let typesStr = String(result.substr(from: 7, to: end-1))
        let subtypes = try Self.typeSplit(type: typesStr).map { try DType(parse: $0) }
        guard subtypes.count == 2 else {
            throw DTypeParsingError.wrongSubtypesCount(count: subtypes.count, expected: 2)
        }
        self = .result(success: subtypes[0], error: subtypes[1])
    }
    
    private static let primitiveUnallowedCharacters: CharacterSet = [
        "[", "]", "{", "}", "<", ">", "(", ")", "\"", ",", " "
    ]
}


