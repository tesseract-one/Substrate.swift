//
//  RuntimeType.swift
//  
//
//  Created by Yehor Popovych on 28.12.2022.
//

import Foundation
import ScaleCodec

public struct RuntimeType: ScaleCodec.Codable, Hashable, Equatable, CustomStringConvertible {
    public let path: [String]
    public let parameters: [Parameter]
    public let definition: Definition
    public let docs: [String]

    public init(
        path: [String],
        parameters: [Parameter],
        definition: Definition,
        docs: [String]
    ) {
        self.path = path
        self.parameters = parameters
        self.definition = definition
        self.docs = docs
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        path = try decoder.decode()
        parameters = try decoder.decode()
        definition = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(path)
        try encoder.encode(parameters)
        try encoder.encode(definition)
        try encoder.encode(docs)
    }
    
    var name: String? {
        !path.isEmpty ? path.joined(separator: ".") : nil
    }
    
    public var description: String {
        if let name = self.name {
            if parameters.isEmpty {
                return "\(name)(\(definition))"
            }
            let params = parameters.map{$0.description}.joined(separator: ", ")
            return "\(name)<\(params)>(\(definition))"
        }
        return definition.description
    }
}

public extension RuntimeType {
    struct Id: ScaleCodec.Codable, Hashable, Equatable,
               ExpressibleByIntegerLiteral, RawRepresentable,
               CustomStringConvertible
    {
        public typealias IntegerLiteralType = UInt32
        public typealias RawValue = UInt32
        
        public let id: UInt32
        
        public var rawValue: UInt32 { id }
        
        public init(id: UInt32) {
            self.id = id
        }
        
        public init(integerLiteral value: UInt32) {
            self.init(id: value)
        }
        
        public init?(rawValue: UInt32) {
            self.id = rawValue
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            id = try decoder.decode(.compact)
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(id, .compact)
        }
        
        public var description: String { String(id) }
    }
}

public extension RuntimeType {
    typealias Registry = [Info]
    
    struct Info: ScaleCodec.Codable, Hashable, Equatable, CustomStringConvertible {
        public let id: Id
        public let type: RuntimeType

        public init(id: Id, type: RuntimeType) {
            self.id = id
            self.type = type
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            id = try decoder.decode()
            type = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(id)
            try encoder.encode(type)
        }
        
        public var description: String {
            "{id: \(id), type: \(type)}"
        }
    }
}

public extension RuntimeType {
    struct Parameter: ScaleCodec.Codable, Hashable, Equatable, CustomStringConvertible {
        public let name: String
        public let type: Id?

        public init(name: String, type: Id?) {
            self.name = name
            self.type = type
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            type = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(type)
        }
        
        public var description: String {
            type == nil ? name : "\(name)#\(type!)"
        }
    }
}

public extension RuntimeType {
    enum Definition: ScaleCodec.Codable, Hashable, Equatable, CustomStringConvertible {
        case composite(fields: [Field])
        case variant(variants: [VariantItem])
        case sequence(of: Id)
        case array(count: UInt32, of: Id)
        case tuple(components: [Id])
        case primitive(is: Primitive)
        case compact(of: Id)
        case bitsequence(store: Id, order: Id)
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            let caseId = try decoder.decode(.enumCaseId)
            switch caseId {
            case 0: self = try .composite(fields: decoder.decode())
            case 1: self = try .variant(variants: decoder.decode())
            case 2: self = try .sequence(of: decoder.decode())
            case 3: self = try .array(count: decoder.decode(), of: decoder.decode())
            case 4: self = try .tuple(components: decoder.decode())
            case 5: self = try .primitive(is: decoder.decode())
            case 6: self = try .compact(of: decoder.decode())
            case 7: self = try .bitsequence(store: decoder.decode(), order: decoder.decode())
            default: throw decoder.enumCaseError(for: caseId)
            }
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            switch self {
            case .composite(fields: let fields):
                try encoder.encode(0, .enumCaseId)
                try encoder.encode(fields)
            case .variant(variants: let vars):
                try encoder.encode(1, .enumCaseId)
                try encoder.encode(vars)
            case .sequence(of: let ty):
                try encoder.encode(2, .enumCaseId)
                try encoder.encode(ty)
            case .array(count: let count, of: let ty):
                try encoder.encode(3, .enumCaseId)
                try encoder.encode(count)
                try encoder.encode(ty)
            case .tuple(components: let cmp):
                try encoder.encode(4, .enumCaseId)
                try encoder.encode(cmp)
            case .primitive(is: let prm):
                try encoder.encode(5, .enumCaseId)
                try encoder.encode(prm)
            case .compact(of: let ty):
                try encoder.encode(6, .enumCaseId)
                try encoder.encode(ty)
            case .bitsequence(store: let sty, order: let oty):
                try encoder.encode(7, .enumCaseId)
                try encoder.encode(sty)
                try encoder.encode(oty)
            }
        }
        
        public var description: String {
            switch self {
            case .composite(fields: let fields): return fields.description
            case .variant(variants: let vars): return vars.description
            case .sequence(of: let id): return "Array<#\(id)>"
            case .array(count: let cnt, of: let id): return "Array<#\(id)>[\(cnt)]"
            case .tuple(components: let fields):
                return "(\(fields.map{"#\($0)"}.joined(separator: ", ")))"
            case .primitive(is: let pr): return pr.description
            case .compact(of: let id): return "Compact<#\(id)>"
            case .bitsequence(store: let sid, order: let ord): return "BitSeq<#\(sid),#\(ord)>"
            }
        }
    }
}

public extension RuntimeType {
    struct Field: ScaleCodec.Codable, Hashable, Equatable, CustomStringConvertible {
        public let name: String?
        public let type: Id
        public let typeName: String?
        public let docs: [String]

        public init(name: String?, type: Id, typeName: String?, docs: [String]) {
            self.name = name
            self.type = type
            self.typeName = typeName
            self.docs = docs
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            type = try decoder.decode()
            typeName = try decoder.decode()
            docs = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(type)
            try encoder.encode(typeName)
            try encoder.encode(docs)
        }
        
        public var description: String {
            let typ = typeName == nil ? "#\(type)" : "(\(typeName!)#\(type))"
            if let name = name {
                return "\(name): \(typ)"
            }
            return typ
        }
    }
}

public extension RuntimeType {
    struct VariantItem: ScaleCodec.Codable, Hashable, Equatable, CustomStringConvertible {
        public let name: String
        public let fields: [Field]
        public let index: UInt8
        public let docs: [String]

        public init(
            name: String, fields: [Field], index: UInt8, docs: [String]
        ) {
            self.name = name
            self.fields = fields
            self.index = index
            self.docs = docs
        }
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            name = try decoder.decode()
            fields = try decoder.decode()
            index = try decoder.decode()
            docs = try decoder.decode()
        }
        
        public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
            try encoder.encode(name)
            try encoder.encode(fields)
            try encoder.encode(index)
            try encoder.encode(docs)
        }
        
        public var description: String {
            if fields.count == 0 {
                return "\(name)[\(index)]"
            }
            return "\(name)[\(index)](\(fields))"
        }
    }
}

public extension RuntimeType {
    enum Primitive: CaseIterable, Hashable, Equatable,
                    ScaleCodec.Codable, CustomStringConvertible
    {
        case bool
        case char
        case str
        case u8
        case u16
        case u32
        case u64
        case u128
        case u256
        case i8
        case i16
        case i32
        case i64
        case i128
        case i256
        
        public var description: String { name }
        
        public var name: String {
            switch self {
            case .bool: return "Bool"
            case .char: return "Character"
            case .str: return "String"
            case .u8: return "UInt8"
            case .u16: return "UInt16"
            case .u32: return "UInt32"
            case .u64: return "UInt64"
            case .u128: return "UInt128"
            case .u256: return "UInt256"
            case .i8: return "Int8"
            case .i16: return "Int16"
            case .i32: return "Int32"
            case .i64: return "Int64"
            case .i128: return "Int128"
            case .i256: return "Int256"
            }
        }
    }
}
