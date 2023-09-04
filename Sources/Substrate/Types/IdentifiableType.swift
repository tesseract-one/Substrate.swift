//
//  IdentifiableType.swift
//  
//
//  Created by Yehor Popovych on 02/09/2023.
//

import Foundation

public indirect enum TypeDefinition: CustomStringConvertible, Hashable, Equatable {
    case composite(fields: [Field])
    case variant(variants: [Variant])
    case sequence(of: Self)
    case array(count: UInt32, of: Self)
    case compact(of: Self)
    case primitive(is: NetworkType.Primitive)
    case bitsequence
    case void
}

public extension TypeDefinition {
    @inlinable
    static var data: Self { .sequence(of: .primitive(is: .u8)) }
    
    @inlinable static func data(count: UInt32) -> Self {
        .array(count: count, of: .primitive(is: .u8))
    }
    
    var description: String {
        switch self {
        case .composite(fields: let fields): return fields.description
        case .variant(variants: let vars): return vars.description
        case .sequence(of: let t): return "[](\(t))"
        case .array(count: let c, of: let t): return "[\(c)](\(t))"
        case .compact(of: let t): return "Compact(\(t))"
        case .primitive(is: let p): return p.description
        case .bitsequence: return "BitSeq"
        case .void: return "()"
        }
    }
}

public extension TypeDefinition {
    struct Field: CustomStringConvertible, Hashable, Equatable {
        public let name: String?
        public let type: TypeDefinition
        
        public init(_ name: String?, _ type: TypeDefinition) {
            self.name = name; self.type = type
        }
        @inlinable
        public static func kv(_ name: String, _ type: TypeDefinition) -> Self {
            Self(name, type)
        }
        @inlinable
        public static func v(_ type: TypeDefinition) -> Self { Self(nil, type) }
        
        public var description: String {
            name != nil ? "\(name!): \(type)" : "\(type)"
        }
    }
}

public extension TypeDefinition {
    struct Variant: CustomStringConvertible, Hashable, Equatable {
        public let index: UInt8
        public let name: String
        public let fields: [Field]
        
        public init(_ index: UInt8, _ name: String, _ fields: [Field]) {
            self.index = index; self.name = name; self.fields = fields
        }
        @inlinable
        public static func e(_ index: UInt8, _ name: String) -> Self {
            Self(index, name, [])
        }
        @inlinable
        public static func s(_ index: UInt8, _ name: String, _ field: Field) -> Self {
            Self(index, name, [field])
        }
        @inlinable
        public static func s(_ index: UInt8, _ name: String, _ field: TypeDefinition) -> Self {
            Self(index, name, [.v(field)])
        }
        @inlinable
        public static func m(_ index: UInt8, _ name: String, _ fields: [Field]) -> Self {
            Self(index, name, fields)
        }
        @inlinable
        public static func m(_ index: UInt8, _ name: String, _ fields: [TypeDefinition]) -> Self {
            Self(index, name, fields.map{.v($0)})
        }
        
        public var description: String {
            fields.count == 0 ? "\(name)[\(index)]"
                : "\(name)[\(index)](\(fields.map{$0.description}.joined(separator: ", ")))"
        }
    }
}

public protocol IdentifiableType: ValidatableType {
    static var definition: TypeDefinition { get }
}


public extension IdentifiableType {
    static func validate(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

public extension TypeDefinition {
    @inlinable
    init(network: NetworkType.Definition, runtime: any Runtime) throws {
        self = try Self.from(network: network, runtime: runtime).get()
    }
    
    @inlinable
    init(type id: NetworkType.Id, runtime: any Runtime) throws {
        self = try Self.from(type: id, runtime: runtime).get()
    }
    
    @inlinable
    static func from(type id: NetworkType.Id,
                     runtime: any Runtime) -> Result<Self, TypeError>
    {
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(path: [], id: id))
        }
        return from(network: type.definition, runtime: runtime)
    }
    
    static func from(network: NetworkType.Definition,
                     runtime: any Runtime) -> Result<Self, TypeError>
    {
        switch network.flatten(metadata: runtime.metadata) {
        case .primitive(is: let p): return .success(.primitive(is: p))
        case .bitsequence(store: _, order: _): return .success(.bitsequence)
        case .array(count: let count, of: let id):
            return from(type: id, runtime: runtime).map{.array(count: count, of: $0)}
        case .compact(of: let id):
            return from(type: id, runtime: runtime).map{.compact(of: $0)}
        case .sequence(of: let id):
            return from(type: id, runtime: runtime).map{.sequence(of: $0)}
        case .tuple(components: let ids):
            return ids.resultMap {
                from(type: $0, runtime: runtime).map{.v($0)}
            }.map { .composite(fields: $0) }
        case .composite(fields: let fields):
            return fields.resultMap { field in
                from(type: field.type, runtime: runtime).map{.init(field.name, $0)}
            }.map { .composite(fields: $0) }
        case .variant(variants: let variants):
            return variants.resultMap { variant in
                return variant.fields.resultMap { field in
                    from(type: field.type, runtime: runtime).map{.init(field.name, $0)}
                }.map { .m(variant.index, variant.name, $0) }
            }.map { .variant(variants: $0) }
        }
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type id: NetworkType.Id) -> Result<Void, TypeError>
    {
        var path: [Self] = []
        return validate(runtime: runtime, type: id, path: &path)
    }
    
    @inlinable
    func validate(runtime: any Runtime, type id: NetworkType.Id,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(path: path, id: id))
        }
        return validate(runtime: runtime, type: type, path: &path)
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: NetworkType) -> Result<Void, TypeError>
    {
        var path: [Self] = []
        return validate(runtime: runtime, type: type, path: &path)
    }
    
    func validate(runtime: any Runtime, type: NetworkType,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        path.append(self); defer { let _ = path.dropLast() }
        switch (self, type.flatten(runtime).definition) {
        case (.array(count: let scount, of: let stype),
              .array(count: let tcount, of: let ttype)):
            guard scount == tcount else {
                return .failure(.wrongValuesCount(path: path,
                                                  expected: Int(scount), in: type))
            }
            return stype.validate(runtime: runtime,
                                  type: ttype,
                                  path: &path)
        case (.sequence(of: let stype), .sequence(of: let ttype)):
            return stype.validate(runtime: runtime,
                                  type: ttype, path: &path)
        case (.compact(of: let stype), .compact(of: let ttype)):
            return validate(compact: stype, runtime: runtime,
                            type: ttype, path: &path)
        case (.primitive(is: let sprim), .primitive(is: let tprim)):
            return sprim == tprim
                ? .success(())
                : .failure(.wrongType(path: path, got: type,
                                      reason: "Expected \(sprim)"))
        case (.bitsequence, .bitsequence(store: _, order: _)): return .success(())
        case (.void, .composite(fields: let fields)):
            return fields.count == 0
                ? .success(())
                : .failure(.wrongType(path: path, got: type,
                                      reason: "Expected empty fields for void"))
        case (.void, .tuple(components: let components)):
            return components.count == 0
                ? .success(())
                : .failure(.wrongType(path: path, got: type,
                                      reason: "Expected empty components for void"))
        case (.composite(fields: let sfields), .composite(fields: let tfields)):
            guard sfields.count == tfields.count else {
                return .failure(.wrongValuesCount(path: path,
                                                  expected: sfields.count, in: type))
            }
            return zip(sfields, tfields).voidErrorMap { sfield, tfield in
                sfield.type.validate(runtime: runtime,
                                     type: tfield.type, path: &path)
            }
        case (.composite(fields: let sfields), .tuple(components: let ids)):
            guard sfields.count == ids.count else {
                return .failure(.wrongValuesCount(path: path, expected: sfields.count, in: type))
            }
            return zip(sfields, ids).voidErrorMap { sfield, id in
                sfield.type.validate(runtime: runtime,
                                     type: id, path: &path)
            }
        case (.variant(variants: let svars), .variant(variants: let tvars)):
            guard svars.count == tvars.count else {
                return .failure(.wrongValuesCount(path: path, expected: svars.count, in: type))
            }
            let tvarsDict = Dictionary(uniqueKeysWithValues: tvars.map { ($0.name, $0) })
            return svars.voidErrorMap { svar in
                guard let inVariant = tvarsDict[svar.name] else {
                    return .failure(.variantNotFound(path: path, variant: svar.name, in: type))
                }
                guard svar.index == inVariant.index else {
                    return .failure(.wrongVariantIndex(path: path, variant: svar.name,
                                                       expected: svar.index, in: type))
                }
                guard svar.fields.count == inVariant.fields.count else {
                    return .failure(.wrongVariantFieldsCount(path: path,
                                                             variant: svar.name,
                                                             expected: svar.fields.count,
                                                             in: type))
                }
                return zip(svar.fields, inVariant.fields).voidErrorMap { field, info in
                    field.type.validate(runtime: runtime,
                                        type: info.type, path: &path)
                }
            }
        default:
            return .failure(.wrongType(path: path, got: type,
                                       reason: "Types can't be matched"))
        }
        
        func validate(compact: Self, runtime: any Runtime,
                      type id: NetworkType.Id, path: inout [Self]) -> Result<Void, TypeError>
        {
            path.append(compact); defer { let _ = path.dropLast() }
            guard let type = runtime.resolve(type: id) else {
                return .failure(.typeNotFound(path: path, id: id))
            }
            switch (compact, type.flatten(runtime).definition) {
            case (.primitive(is: let sprim), .primitive(is: let iprim)):
                guard let suint = sprim.isUInt, let iuint = iprim.isUInt else {
                    return .failure(.wrongType(path: path,
                                               got: type,
                                               reason: "primitive is not UInt"))
                }
                guard iuint <= suint else {
                    return .failure(.wrongType(path: path, got: type,
                                               reason: "UInt\(suint) can't store\(iuint) bits"))
                }
            case (.void, let t):
                guard t.isEmpty(metadata: runtime.metadata) else {
                    return .failure(.wrongType(path: path, got: type,
                                               reason: "Got type for Compact<Void>"))
                }
            default:
                return .failure(.wrongType(path: path, got: type,
                                           reason: "Can't be Compact"))
            }
            return .success(())
        }
    }
}

public extension TypeError {
    static func typeNotFound(path: [TypeDefinition], id: NetworkType.Id) -> Self {
        .typeNotFound(for: path.pathString, id: id)
    }
    
    static func wrongType(path: [TypeDefinition], got: NetworkType, reason: String) -> Self {
        .wrongType(for: path.pathString, got: got, reason: reason)
    }
    
    static func wrongValuesCount(path: [TypeDefinition], expected: Int, in: NetworkType) -> Self {
        .wrongValuesCount(for: path.pathString, expected: expected, in: `in`)
    }
        
    static func fieldNotFound(path: [TypeDefinition], field: String, in: NetworkType) -> Self {
        .fieldNotFound(for: path.pathString, field: field, in: `in`)
    }
            
    static func variantNotFound(path: [TypeDefinition], variant: String, in: NetworkType) -> Self {
        .variantNotFound(for: path.pathString, variant: variant, in: `in`)
    }
    
    static func wrongVariantFieldsCount(path: [TypeDefinition], variant: String,
                                        expected: Int, in: NetworkType) -> Self {
        .wrongVariantFieldsCount(for: path.pathString, variant: variant,
                                 expected: expected, in: `in`)
    }
    
    static func wrongVariantIndex(path: [TypeDefinition], variant: String,
                                  expected: UInt8, in: NetworkType) -> Self {
        .wrongVariantIndex(for: path.pathString, variant: variant,
                           expected: expected, in: `in`)
    }
}

private extension Array where Element == TypeDefinition {
    var pathString: String { map { $0.description }.joined(separator: ".") }
}
