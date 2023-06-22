//
//  PortableTypes.swift
//  
//
//  Created by Yehor Popovych on 28.12.2022.
//

import Foundation
import ScaleCodec

public struct RuntimeTypeId: ScaleCodable, Hashable, Equatable,
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
    
    public init(from decoder: ScaleCodec.ScaleDecoder) throws {
        id = try decoder.decode(.compact)
    }
    
    public func encode(in encoder: ScaleCodec.ScaleEncoder) throws {
        try encoder.encode(id, .compact)
    }
    
    public var description: String { String(id) }
}

public struct RuntimeTypeInfo: CustomStringConvertible {
    public let id: RuntimeTypeId
    public let type: RuntimeType

    public init(id: RuntimeTypeId, type: RuntimeType) {
        self.id = id
        self.type = type
    }
    
    public var description: String {
        "{id: \(id), type: \(type)}"
    }
}

extension RuntimeTypeInfo: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        id = try decoder.decode()
        type = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(id).encode(type)
    }
}

public struct RuntimeType: CustomStringConvertible {
    public let path: [String]
    public let parameters: [RuntimeTypeParameter]
    public let definition: RuntimeTypeDefinition
    public let docs: [String]

    public init(
        path: [String],
        parameters: [RuntimeTypeParameter],
        definition: RuntimeTypeDefinition,
        docs: [String]
    ) {
        self.path = path
        self.parameters = parameters
        self.definition = definition
        self.docs = docs
    }
    
    public var description: String {
        if let name = pathBasedName {
            if parameters.isEmpty {
                return "\(name)(\(definition))"
            }
            let params = parameters.map{$0.description}.joined(separator: ", ")
            return "\(name)<\(params)>(\(definition))"
        }
        return definition.description
    }
}

extension RuntimeType {
    var pathBasedName: String? {
        !path.isEmpty ? path.joined(separator: ".") : nil
    }
}

extension RuntimeType: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        path = try decoder.decode()
        parameters = try decoder.decode()
        definition = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(path).encode(parameters)
            .encode(definition).encode(docs)
    }
}

public struct RuntimeTypeParameter: CustomStringConvertible {
    public let name: String
    public let type: RuntimeTypeId?

    public init(name: String, type: RuntimeTypeId?) {
        self.name = name
        self.type = type
    }
    
    public var description: String {
        type == nil ? name : "\(name)#\(type!)"
    }
}

extension RuntimeTypeParameter: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(type)
    }
}

public enum RuntimeTypeDefinition {
    case composite(fields: [RuntimeTypeField])
    case variant(variants: [RuntimeTypeVariantItem])
    case sequence(of: RuntimeTypeId)
    case array(count: UInt32, of: RuntimeTypeId)
    case tuple(components: [RuntimeTypeId])
    case primitive(is: RuntimeTypePrimitive)
    case compact(of: RuntimeTypeId)
    case bitsequence(store: RuntimeTypeId, order: RuntimeTypeId)
}

extension RuntimeTypeDefinition: CustomStringConvertible {
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

extension RuntimeTypeDefinition: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
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
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .composite(fields: let fields): try encoder.encode(0, .enumCaseId).encode(fields)
        case .variant(variants: let vars): try encoder.encode(1, .enumCaseId).encode(vars)
        case .sequence(of: let ty): try encoder.encode(2, .enumCaseId).encode(ty)
        case .array(count: let count, of: let ty):
            try encoder.encode(3, .enumCaseId).encode(count).encode(ty)
        case .tuple(components: let cmp): try encoder.encode(4, .enumCaseId).encode(cmp)
        case .primitive(is: let prm): try encoder.encode(5, .enumCaseId).encode(prm)
        case .compact(of: let ty): try encoder.encode(6, .enumCaseId).encode(ty)
        case .bitsequence(store: let sty, order: let oty):
            try encoder.encode(7, .enumCaseId).encode(sty).encode(oty)
        }
    }
}

public struct RuntimeTypeField: CustomStringConvertible {
    public let name: String?
    public let type: RuntimeTypeId
    public let typeName: String?
    public let docs: [String]

    public init(name: String?, type: RuntimeTypeId, typeName: String?, docs: [String]) {
        self.name = name
        self.type = type
        self.typeName = typeName
        self.docs = docs
    }
    
    public var description: String {
        let typ = typeName == nil ? "#\(type)" : "(\(typeName!)#\(type))"
        if let name = name {
            return "\(name): \(typ)"
        }
        return typ
    }
}

extension RuntimeTypeField: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
        typeName = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(type)
            .encode(typeName).encode(docs)
    }
}

public struct RuntimeTypeVariantItem: CustomStringConvertible {
    public let name: String
    public let fields: [RuntimeTypeField]
    public let index: UInt8
    public let docs: [String]

    public init(
        name: String,
        fields: [RuntimeTypeField],
        index: UInt8,
        docs: [String]
    ) {
        self.name = name
        self.fields = fields
        self.index = index
        self.docs = docs
    }
    
    public var description: String {
        if fields.count == 0 {
            return "\(name)[\(index)]"
        }
        return "\(name)[\(index)](\(fields))"
    }
}

extension RuntimeTypeVariantItem: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        fields = try decoder.decode()
        index = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(fields)
            .encode(index).encode(docs)
    }
}

public enum RuntimeTypePrimitive: String, CaseIterable, ScaleCodable, CustomStringConvertible {
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
    
    public var name: String { rawValue }
    public var description: String { name }
}
