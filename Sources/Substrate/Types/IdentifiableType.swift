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
    case bitsequence(store: BitSequence.Format.Store, order: BitSequence.Format.Order)
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

public protocol IdentifiableTypeStatic: ValidatableTypeStatic {
    static var definition: TypeDefinition { get }
}


public extension IdentifiableTypeStatic {
    static func validate(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, for: Self.self, type: type.type)
    }
}

public typealias IdentifiableType = IdentifiableTypeStatic & ValidatableType

public extension TypeDefinition {
    @inlinable
    init(type id: NetworkType.Id, for type: Any.Type, runtime: any Runtime) throws {
        self = try Self.from(type: id, for: type, runtime: runtime).get()
    }
    
    @inlinable
    static func from(type id: NetworkType.Id,
                     for type: Any.Type,
                     runtime: any Runtime) -> Result<Self, TypeError>
    {
        from(type: id, for: String(describing: type), runtime: runtime)
    }
    
    @inlinable
    static func from(type id: NetworkType.Id,
                     for type: String,
                     runtime: any Runtime) -> Result<Self, TypeError>
    {
        guard let _type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: type,
                                          path: [] as [NetworkType.Id],
                                          id: id, .get()))
        }
        return from(type: id.i(_type), for: type, runtime: runtime)
    }
    
    @inlinable
    static func from(type info: NetworkType.Info,
                     for type: Any.Type,
                     runtime: any Runtime) -> Result<Self, TypeError>
    {
        from(type: info, for: String(describing: type), runtime: runtime)
    }
    
    @inlinable
    static func from(type info: NetworkType.Info,
                     for type: String,
                     runtime: any Runtime) -> Result<Self, TypeError>
    {
        var path: [NetworkType.Id] = [info.id]
        defer { let _ = path.removeLast() }
        return from(network: info.type.definition,
                    for: type, runtime: runtime, path: &path)
    }
    
    @inlinable
    static func from(type id: NetworkType.Id,
                     for type: String,
                     runtime: any Runtime,
                     path: inout [NetworkType.Id]) -> Result<Self, TypeError>
    {
        guard !path.contains(id) else {
            path.append(id)
            return .failure(.recursiveType(for: type, path: path, .get()))
        }
        guard let _type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: type, path: path,
                                          id: id, .get()))
        }
        path.append(id); defer { let _ = path.removeLast() }
        return from(network: _type.definition, for: type,
                    runtime: runtime, path: &path)
    }
    
    static func from(network: NetworkType.Definition,
                     for type: String,
                     runtime: any Runtime,
                     path: inout [NetworkType.Id]) -> Result<Self, TypeError>
    {
        
        switch network.flatten(metadata: runtime.metadata) {
        case .primitive(is: let p): return .success(.primitive(is: p))
        case .bitsequence(store: let s, order: let o):
            return BitSequence.Format.Store.from(type: s, runtime: runtime).flatMap { st in
                BitSequence.Format.Order.from(type: o, runtime: runtime).map {
                    .bitsequence(store: st, order: $0)
                }
            }
        case .array(count: let count, of: let id):
            return from(type: id, for: type, runtime: runtime,
                        path: &path).map{.array(count: count, of: $0)}
        case .compact(of: let id):
            return from(type: id, for: type, runtime: runtime,
                        path: &path).map{.compact(of: $0)}
        case .sequence(of: let id):
            return from(type: id, for: type, runtime: runtime,
                        path: &path).map{.sequence(of: $0)}
        case .tuple(components: let ids):
            return ids.resultMap {
                from(type: $0, for: type,
                     runtime: runtime, path: &path).map{.v($0)}
            }.map { .composite(fields: $0) }
        case .composite(fields: let fields):
            return fields.resultMap { field in
                from(type: field.type, for: type,
                     runtime: runtime, path: &path).map{.init(field.name, $0)}
            }.map { .composite(fields: $0) }
        case .variant(variants: let variants):
            return variants.resultMap { variant in
                return variant.fields.resultMap { field in
                    from(type: field.type, for: type,
                         runtime: runtime, path: &path).map{.init(field.name, $0)}
                }.map { .m(variant.index, variant.name, $0) }
            }.map { .variant(variants: $0) }
        }
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  for type: Any.Type,
                  type id: NetworkType.Id) -> Result<Void, TypeError>
    {
        validate(runtime: runtime, for: String(describing: type), type: id)
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  for type: String,
                  type id: NetworkType.Id) -> Result<Void, TypeError>
    {
        var path: [Self] = []
        return validate(runtime: runtime, type: id, for: type, path: &path)
    }
    
    @inlinable
    func validate(runtime: any Runtime, type id: NetworkType.Id,
                  for type: String, path: inout [Self]) -> Result<Void, TypeError>
    {
        guard let _type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: type, path: path,
                                          id: id, .get()))
        }
        return validate(runtime: runtime, type: _type, for: type,  path: &path)
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  for _type: Any.Type,
                  type: NetworkType) -> Result<Void, TypeError>
    {
        validate(runtime: runtime, for: String(describing: _type), type: type)
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  for _type: String,
                  type: NetworkType) -> Result<Void, TypeError>
    {
        var path: [Self] = []
        return validate(runtime: runtime, type: type, for: _type, path: &path)
    }
    
    func validate(runtime: any Runtime, type: NetworkType,
                  for _type: String,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        path.append(self); defer { let _ = path.dropLast() }
        let flat = type.flatten(runtime)
        switch (self, flat.definition) {
        case (.array(count: let count, of: let stype), _):
            return validate(arrayOf: stype, count: count, type: flat,
                            for: _type, runtime: runtime, path: &path)
        case (.composite(fields: let fields), _):
            return validate(composite: fields, type: flat,
                            for: _type, runtime: runtime, path: &path)
        case (.variant(variants: let vars), _):
            return validate(variant: vars, type: flat,
                            for: _type, runtime: runtime, path: &path)
        case (.void, _):
            return validate(void: flat, runtime: runtime,
                            for: _type, path: &path)
        case (.compact(of: let stype), .compact(of: let ttype)):
            return validate(compact: stype, runtime: runtime,
                            for: _type, type: ttype, path: &path)
        case (.sequence(of: let stype), .sequence(of: let ttype)):
            return stype.validate(runtime: runtime,
                                  type: ttype, for: _type, path: &path)
        case (.primitive(is: let sprim), .primitive(is: let tprim)):
            return sprim == tprim ? .success(())
                : .failure(.wrongType(for: _type, path: path, type: type,
                                      reason: "Expected \(sprim)", .get()))
        case (.bitsequence(store: let ss, order: let so),
              .bitsequence(store: let tsId, order: let toId)):
            return BitSequence.Format.Store.from(type: tsId, runtime: runtime).flatMap { ts in
                BitSequence.Format.Order.from(type: toId, runtime: runtime).flatMap {
                    guard ss == ts else {
                        return .failure(.wrongType(for: _type, path: path, type: type,
                                                   reason: "Expected \(ss) store format",
                                                   .get()))
                    }
                    return so == $0 ? .success(()) :
                        .failure(.wrongType(for: _type, path: path, type: type,
                                            reason: "Expected \(so) order", .get()))
                }
            }
        default:
            return .failure(.wrongType(for: _type, path: path, type: type,
                                       reason: "Types can't be matched", .get()))
        }
    }
    
    func validate(arrayOf stype: Self, count: UInt32, type: NetworkType,
                  for _type: String, runtime: any Runtime,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .array(count: let tcount, of: let ttype):
            guard count == tcount else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: Int(count),
                                                  type: type, .get()))
            }
            return stype.validate(runtime: runtime, type: ttype,
                                  for: _type, path: &path)
        case .composite(fields: let tfields):
            guard count == tfields.count else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: Int(count),
                                                  type: type, .get()))
            }
            return tfields.voidErrorMap { info in
                stype.validate(runtime: runtime, type: info.type, for: _type, path: &path)
            }
        case .tuple(components: let ids):
            guard count == ids.count else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: Int(count),
                                                  type: type, .get()))
            }
            return ids.voidErrorMap { id in
                stype.validate(runtime: runtime, type: id,
                               for: _type, path: &path)
            }
        default: return .failure(.wrongType(for: _type, path: path, type: type,
                                            reason: "Type isn't array compatible",
                                            .get()))
        }
    }
    
    func validate(variant vars: [Variant], type: NetworkType,
                  for _type: String, runtime: any Runtime,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .variant(variants: let tvars):
            guard vars.count == tvars.count else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: vars.count,
                                                  type: type, .get()))
            }
            let tvarsDict = Dictionary(uniqueKeysWithValues: tvars.map { ($0.name, $0) })
            return vars.voidErrorMap { svar in
                guard let inVariant = tvarsDict[svar.name] else {
                    return .failure(.variantNotFound(for: _type, path: path,
                                                     variant: svar.name,
                                                     type: type, .get()))
                }
                guard svar.index == inVariant.index else {
                    return .failure(.wrongVariantIndex(for: _type, path: path,
                                                       variant: svar.name,
                                                       expected: svar.index,
                                                       type: type, .get()))
                }
                guard svar.fields.count == inVariant.fields.count else {
                    return .failure(.wrongVariantFieldsCount(for: _type, path: path,
                                                             variant: svar.name,
                                                             expected: svar.fields.count,
                                                             type: type, .get()))
                }
                return zip(svar.fields, inVariant.fields).voidErrorMap { field, info in
                    field.type.validate(runtime: runtime, type: info.type,
                                        for: _type, path: &path)
                }
            }
        default: return .failure(.wrongType(for: _type, path: path, type: type,
                                            reason: "Type isn't variant compatible",
                                            .get()))
        }
    }
    
    func validate(composite fields: [Field], type: NetworkType,
                  for _type: String, runtime: any Runtime,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .composite(fields: let tfields):
            guard fields.count == tfields.count else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: fields.count,
                                                  type: type, .get()))
            }
            return zip(fields, tfields).voidErrorMap { sfield, tfield in
                sfield.type.validate(runtime: runtime, type: tfield.type,
                                     for: _type, path: &path)
            }
        case .tuple(components: let ids):
            guard fields.count == ids.count else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: fields.count,
                                                  type: type, .get()))
            }
            return zip(fields, ids).voidErrorMap { sfield, id in
                sfield.type.validate(runtime: runtime, type: id,
                                     for: _type, path: &path)
            }
        case .array(count: let count, of: let id):
            guard fields.count == count else {
                return .failure(.wrongValuesCount(for: _type, path: path,
                                                  expected: fields.count,
                                                  type: type, .get()))
            }
            return fields.voidErrorMap { sfield in
                sfield.type.validate(runtime: runtime, type: id,
                                     for: _type, path: &path)
            }
        default: return .failure(.wrongType(for: _type, path: path, type: type,
                                            reason: "Type isn't composite compatible",
                                            .get()))
        }
    }
    
    func validate(void type: NetworkType, runtime: any Runtime,
                  for _type: String, path: inout [Self]) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .tuple(components: let components):
            return components.count == 0
                ? .success(())
                : .failure(.wrongType(for: _type, path: path, type: type,
                                      reason: "Expected empty components for void",
                                      .get()))
        case .composite(fields: let fields):
            return fields.count == 0
                ? .success(())
                : .failure(.wrongType(for: _type, path: path, type: type,
                                      reason: "Expected empty fields for void",
                                      .get()))
        case .variant(variants: let vars):
            return vars.count == 0
                ? .success(())
                : .failure(.wrongType(for: _type, path: path, type: type,
                                      reason: "Expected empty variants for void",
                                      .get()))
        case .array(count: let count, of: _):
            return count == 0
                ? .success(())
                : .failure(.wrongType(for: _type, path: path, type: type,
                                      reason: "Expected 0 elements for void",
                                      .get()))
        default: return .failure(.wrongType(for: _type, path: path, type: type,
                                            reason: "Type isn't void compatible",
                                            .get()))
        }
    }
    
    func validate(compact: Self, runtime: any Runtime,
                  for _type: String, type id: NetworkType.Id,
                  path: inout [Self]) -> Result<Void, TypeError>
    {
        path.append(compact); defer { let _ = path.dropLast() }
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: _type, path: path, id: id, .get()))
        }
        switch (compact, type.flatten(runtime).definition) {
        case (.primitive(is: let sprim), .primitive(is: let iprim)):
            guard let suint = sprim.isUInt, let iuint = iprim.isUInt else {
                return .failure(.wrongType(for: _type, path: path, type: type,
                                           reason: "primitive is not UInt", .get()))
            }
            guard iuint <= suint else {
                return .failure(.wrongType(for: _type, path: path, type: type,
                                           reason: "UInt\(suint) can't store\(iuint) bits",
                                           .get()))
            }
        case (.void, let t):
            guard t.isEmpty(metadata: runtime.metadata) else {
                return .failure(.wrongType(for: _type, path: path, type: type,
                                           reason: "Got type for Compact<Void>",
                                           .get()))
            }
        default:
            return .failure(.wrongType(for: _type, path: path, type: type,
                                       reason: "Can't be Compact", .get()))
        }
        return .success(())
    }
}

public extension TypeError {
    @inlinable
    static func typeNotFound(for _type: String,
                             path: [TypeDefinition],
                             id: NetworkType.Id,
                             _ info: ErrorMethodInfo) -> Self
    {
        .typeNotFound(for: "\(_type)=>\(path.pathString)",
                      id: id, info: info)
    }
    
    @inlinable
    static func typeNotFound(for _type: String,
                             path: [NetworkType.Id],
                             id: NetworkType.Id,
                             _ info: ErrorMethodInfo) -> Self
    {
        let sPath = path.map{"#\($0)"}.joined(separator: ".")
        return .typeNotFound(for: "\(_type)=>\(sPath)",
                             id: id, info: info)
    }
    
    @inlinable
    static func recursiveType(for _type: String,
                              path: [NetworkType.Id],
                              _ info: ErrorMethodInfo) -> Self
    {
        let sPath = path.map{"#\($0)"}.joined(separator: ".")
        return .recursiveType(for: "\(_type)=>\(sPath)", info: info)
    }
    
    @inlinable
    static func wrongType(for _type: String,
                          path: [TypeDefinition],
                          type: NetworkType, reason: String,
                          _ info: ErrorMethodInfo) -> Self
    {
        .wrongType(for: "\(_type)=>\(path.pathString)",
                   type: type, reason: reason, info: info)
    }
    
    @inlinable
    static func wrongValuesCount(for _type: String,
                                 path: [TypeDefinition], expected: Int,
                                 type: NetworkType,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .wrongValuesCount(for: "\(_type)=>\(path.pathString)",
                          expected: expected, type: type, info: info)
    }
    
    @inlinable
    static func fieldNotFound(for _type: String,
                              path: [TypeDefinition],
                              field: String, type: NetworkType,
                              _ info: ErrorMethodInfo) -> Self
    {
        .fieldNotFound(for: "\(_type)=>\(path.pathString)", field: field,
                       type: type, info: info)
    }
    
    @inlinable
    static func variantNotFound(for _type: String,
                                path: [TypeDefinition],
                                variant: String,
                                type: NetworkType,
                                _ info: ErrorMethodInfo) -> Self
    {
        .variantNotFound(for: "\(_type)=>\(path.pathString)",
                         variant: variant, type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantFieldsCount(for _type: String,
                                        path: [TypeDefinition],
                                        variant: String,
                                        expected: Int, type: NetworkType,
                                        _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantFieldsCount(for: "\(_type)=>\(path.pathString)",
                                 variant: variant, expected: expected,
                                 type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantIndex(for _type: String,
                                  path: [TypeDefinition],
                                  variant: String, expected: UInt8,
                                  type: NetworkType,
                                  _ info: ErrorMethodInfo) -> Self {
        .wrongVariantIndex(for: "\(_type)=>\(path.pathString)",
                           variant: variant, expected: expected,
                           type: type, info: info)
    }
}

public extension Array where Element == TypeDefinition {
    var pathString: String { map { "\($0)" }.joined(separator: ".") }
}
