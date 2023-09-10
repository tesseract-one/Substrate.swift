//
//  TypeDefinition.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

prefix operator *

public protocol AnyTypeDefinition: Equatable, Hashable, CustomStringConvertible {
    var name: String { get }
    var parameters: [TypeDefinition.Parameter]? { get }
    var definition: TypeDefinition.Def { get }
    var docs: [String]? { get }
    
    var weak: TypeDefinition.Weak { get }
    var strong: TypeDefinition { get }
    var objectId: ObjectIdentifier { get }
}

public struct TypeDefinition: AnyTypeDefinition {
    @inlinable public var name: String { _storage.name }
    @inlinable public var parameters: [Parameter]? { _storage.parameters }
    @inlinable public var definition: Def { _storage.definition }
    @inlinable public var docs: [String]? { _storage.docs }
    
    @inlinable public var weak: Weak { _storage.weak }
    @inlinable public var strong: Self { self }
    @inlinable public var objectId: ObjectIdentifier { _storage.id }
    
    public let _storage: Storage
    public let _registry: AnyObject
    
    public init(storage: Storage, registry: AnyObject) {
        self._storage = storage
        self._registry = registry
    }
}

public extension TypeDefinition {
    enum Def: Equatable, Hashable {
        case composite(fields: [Field])
        case variant(variants: [Variant])
        case sequence(of: TypeDefinition.Weak)
        case array(count: UInt32, of: TypeDefinition.Weak)
        case compact(of: TypeDefinition.Weak)
        case primitive(is: NetworkType.Primitive)
        case bitsequence(format: BitSequence.Format)
        case void
        
        @inlinable
        public static func sequence(of def: TypeDefinition) -> Self {
            .sequence(of: def.weak)
        }
        @inlinable
        public static func array(count: UInt32, of def: TypeDefinition) -> Self {
            .array(count: count, of: def.weak)
        }
        @inlinable
        public static func compact(of def: TypeDefinition) -> Self {
            .compact(of: def.weak)
        }
    }
}

public extension TypeDefinition {
    struct Field: Equatable, Hashable, CustomStringConvertible {
        public let name: String?
        public let type: TypeDefinition.Weak
        public let typeName: String? = nil
        public let docs: [String]? = nil
        
        public init(_ name: String?, _ type: TypeDefinition.Weak) {
            self.name = name; self.type = type
        }
        @inlinable
        public static func kv(_ name: String, _ type: TypeDefinition) -> Self {
            Self(name, type.weak)
        }
        @inlinable
        public static func kv(_ name: String, _ type: TypeDefinition.Weak) -> Self {
            Self(name, type)
        }
        @inlinable
        public static func okv(_ name: String?, _ type: TypeDefinition) -> Self {
            Self(name, type.weak)
        }
        @inlinable
        public static func okv(_ name: String?, _ type: TypeDefinition.Weak) -> Self {
            Self(name, type)
        }
        @inlinable
        public static func v(_ type: TypeDefinition) -> Self { Self(nil, type.weak) }
        @inlinable
        public static func v(_ type: TypeDefinition.Weak) -> Self { Self(nil, type) }
        
        public var description: String {
            name != nil ? "\(name!): \(type)" : "\(type)"
        }
    }
}

public extension TypeDefinition {
    struct Variant: Equatable, Hashable, CustomStringConvertible {
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
            Self(index, name, [.v(field.weak)])
        }
        @inlinable
        public static func m(_ index: UInt8, _ name: String, _ fields: [Field]) -> Self {
            Self(index, name, fields)
        }
        @inlinable
        public static func m(_ index: UInt8, _ name: String, _ fields: [TypeDefinition]) -> Self {
            Self(index, name, fields.map{.v($0.weak)})
        }
        
        public var description: String {
            fields.count == 0 ? "\(name)[\(index)]"
                : "\(name)[\(index)](\(fields.map{$0.description}.joined(separator: ", ")))"
        }
    }
}

public extension TypeDefinition {
    struct Parameter: Hashable, Equatable, CustomStringConvertible {
        public let name: String
        public let type: TypeDefinition.Weak?
        
        
        public init(name: String, type: TypeDefinition.Weak?) {
            self.name = name
            self.type = type
        }
        @inlinable
        public static func n(_ name: String) -> Self {
            Self(name: name, type: nil)
        }
        @inlinable
        public static func t(_ name: String, _ type: TypeDefinition.Weak) -> Self {
            Self(name: name, type: type)
        }
        @inlinable
        public static func t(_ name: String, _ type: TypeDefinition) -> Self {
            Self(name: name, type: type.weak)
        }
        public var description: String {
            type == nil ? name : "\(name): \(type!)"
        }
    }
}

public extension TypeDefinition {
    struct Weak: AnyTypeDefinition {
        public var name: String { _storage.name }
        public var parameters: [Parameter]? { _storage.parameters }
        public var definition: Def { _storage.definition }
        public var docs: [String]? { _storage.docs }
        
        public var strong: TypeDefinition { _storage.strong }
        @inlinable public var weak: Self { self }
        public var objectId: ObjectIdentifier { _storage.id }
        
        public static prefix func * (def: Self) -> TypeDefinition { def._storage.strong }
        
        public private(set) weak var _storage: Storage!
        
        public init(storage: Storage) {
            self._storage = storage
        }
    }
    
    final class Storage: Equatable, Hashable, CustomStringConvertible {
        public var name: String { _name }
        public var definition: Def { _definition }
        public var parameters: [Parameter]? { _parameters }
        public var docs: [String]? { _docs }
        
        public var weak: Weak { Weak(storage: self) }
        public var strong: TypeDefinition {
            TypeDefinition(storage: self, registry: _registry)
        }
        public var id: ObjectIdentifier { ObjectIdentifier(self) }
        
        public var description: String { self.weak.description }
        
        public init<Id: Hashable>(registry: TypeRegistry<Id>) {
            self._registry = registry
            self._definition = .void
        }
        
        public func initialize<E: Error>(
            _ ctr: () -> Result<TypeDefinition.Builder, E>
        ) -> Result<TypeDefinition, E> {
            ctr().map { bd in
                self._name = bd.params.name!
                self._parameters = bd.params.parameters
                self._definition = bd.def
                self._docs = bd.params.docs
                return self.strong
            }
        }
        
        public func hash(into hasher: inout Swift.Hasher) {
            hasher.combine(self.weak)
        }
        
        public static func == (lhs: Storage, rhs: Storage) -> Bool {
            lhs.weak == rhs.weak
        }
        
        private var _definition: Def
        private var _name: String!
        private var _parameters: [Parameter]?
        private var _docs: [String]?
        private weak var _registry: AnyObject!
    }
    
    struct TypeId: Hashable, Equatable {
        let type: ObjectIdentifier
        let config: String?
        
        public init<T>(type: T.Type, config: String?) {
            self.type = ObjectIdentifier(type)
            self.config = config
        }
    }
    
    struct Builder {
        public struct OptParams {
            public let name: String?
            public let parameters: [Parameter]?
            public let docs: [String]?
            
            public init(name: String? = nil,
                        parameters: [Parameter]? = nil,
                        docs: [String]? = nil)
            {
                self.name = name
                self.parameters = parameters
                self.docs = docs
            }
            
            @inlinable
            public static func name(_ name: String) -> Self {
                Self(name: name)
            }
            @inlinable
            public static func parameters(_ params: [Parameter]) -> Self {
                Self(parameters: params)
            }
            @inlinable
            public static func docs(_ docs: [String]) -> Self {
                Self(docs: docs)
            }
            @inlinable
            public static func info(name: String,
                                    parameters: [Parameter]?,
                                    docs: [String]?) -> Self
            {
                Self(name: name, parameters: parameters)
            }
            @inlinable
            public func name(_ name: String) -> Self {
                Self(name: name, parameters: parameters, docs: docs)
            }
            @inlinable
            public func parameters(_ parameters: [Parameter]) -> Self {
                Self(name: name, parameters: parameters, docs: docs)
            }
            @inlinable
            public func docs(_ docs: [String]) -> Self {
                Self(name: name, parameters: parameters, docs: docs)
            }
            @inlinable
            public static var empty: Self { Self() }
            @inlinable
            public func composite(fields: [Field]) -> TypeDefinition.Builder {
                .def(.composite(fields: fields))
            }
            @inlinable
            public func variant(variants: [Variant]) -> TypeDefinition.Builder {
                .def(.variant(variants: variants))
            }
            @inlinable
            public func sequence(of: TypeDefinition) -> TypeDefinition.Builder {
                .def(.sequence(of: of))
            }
            @inlinable
            public func array(count: UInt32, of: TypeDefinition) -> TypeDefinition.Builder {
                .def(.array(count: count, of: of))
            }
            @inlinable
            public func compact(of: TypeDefinition) -> TypeDefinition.Builder {
                .def(.compact(of: of))
            }
            @inlinable
            public func primitive(is: NetworkType.Primitive) -> TypeDefinition.Builder {
                .def(.primitive(is: `is`))
            }
            @inlinable
            public func bitsequence(format: BitSequence.Format) -> TypeDefinition.Builder {
                .def(.bitsequence(format: format))
            }
            @inlinable
            public func def(_ def: Def) -> TypeDefinition.Builder {
                TypeDefinition.Builder(def: def, params: self)
            }
            @inlinable
            public var void: TypeDefinition.Builder { .def(.void) }
        }
        
        public let def: Def
        public let params: OptParams
        
        public init(def: Def, params: OptParams) {
            self.def = def
            self.params = params
        }
        
        @inlinable
        public static func name(_ name: String) -> OptParams { .name(name) }
        @inlinable
        public static func parameters(_ parameters: [Parameter]) -> OptParams {
            .parameters(parameters)
        }
        @inlinable
        public static func docs(_ docs: [String]) -> OptParams {
            .docs(docs)
        }
        @inlinable
        public static func info(name: String,
                                parameters: [Parameter]?,
                                docs: [String]?) -> OptParams
        {
            .info(name: name, parameters: parameters, docs: docs)
        }
        @inlinable
        public static func composite(fields: [Field]) -> Self {
            .def(.composite(fields: fields))
        }
        @inlinable
        public static func variant(variants: [Variant]) -> Self {
            .def(.variant(variants: variants))
        }
        @inlinable
        public static func sequence(of: TypeDefinition) -> Self {
            .def(.sequence(of: of))
        }
        @inlinable
        public static func array(count: UInt32, of: TypeDefinition) -> Self {
            .def(.array(count: count, of: of))
        }
        @inlinable
        public static func compact(of: TypeDefinition) -> Self {
            .def(.compact(of: of))
        }
        @inlinable
        public static func primitive(is: NetworkType.Primitive) -> Self {
            .def(.primitive(is: `is`))
        }
        @inlinable
        public static func bitsequence(format: BitSequence.Format) -> Self {
            .def(.bitsequence(format: format))
        }
        @inlinable
        public static func def(_ def: Def) -> Self {
            Self(def: def, params: .empty)
        }
        @inlinable
        public static var void: Self { .def(.void) }
        @inlinable
        public func name(_ name: String) -> Self {
            params.name(name).def(def)
        }
        @inlinable
        public func parameters(_ parameters: [Parameter]) -> Self {
            params.parameters(parameters).def(def)
        }
        @inlinable
        public func docs(_ docs: [String]) -> Self {
            params.docs(docs).def(def)
        }
        @inlinable
        public func info(name: String, parameters: [Parameter]?, docs: [String]?) -> Self {
            Self.info(name: name, parameters: parameters, docs: docs).def(def)
        }
    }
}

public extension Optional where Wrapped == TypeDefinition.Weak {
    @inlinable
    static prefix func * (odef: Self) -> TypeDefinition? { odef.map { $0.strong } }
}

public extension AnyTypeDefinition {
    @inlinable var fullName: String {
        (parameters?.count ?? 0) == 0 ? name
            : "\(name)<\(parameters!.map{$0.name}.joined(separator: ", "))>"
    }
    
    @inlinable func flatten() -> TypeDefinition {
        switch self.definition {
        case .composite(fields: let fields):
            guard fields.count == 1 else { return self.strong }
            return fields[0].type.flatten()
        default: return self.strong
        }
    }
    
    @inlinable func asPrimitive() -> NetworkType.Primitive? {
        switch flatten().definition {
        case .primitive(let p): return p
        case .compact(of: let type): return type.asPrimitive()
        default: return nil
        }
    }
    
    @inlinable func asResult() -> (ok: TypeDefinition.Field, err: TypeDefinition.Field)? {
        switch flatten().definition {
        case .variant(variants: let vars):
            guard vars.count == 2 else { return nil }
            guard let ok = vars.first(where: {$0.name == "Ok"}) else { return nil }
            guard let err = vars.first(where: {$0.name == "Err"}) else { return nil }
            return (ok: ok.fields.first!, err: err.fields.first!)
        default: return nil
        }
    }
    
    @inlinable func asCompact() -> TypeDefinition? {
        switch flatten().definition {
        case .compact(of: let of): return of.flatten()
        default: return nil
        }
    }
    
    @inlinable func asOptional() -> TypeDefinition.Field? {
        switch flatten().definition {
        case .variant(variants: let vars):
            guard vars.count == 2 else { return nil }
            guard let some = vars.first(where: {$0.name == "Some"}) else { return nil }
            return some.fields.first!
        default: return nil
        }
    }
    
    @inlinable func isEmpty() -> Bool {
        switch flatten().definition {
        case .array(count: let c, of: _): return c == 0
        case .composite(fields: let f): return f.count == 0
        case .void: return true
        default: return false
        }
    }
    
    @inlinable func isBitSequence() -> Bool {
        switch flatten().definition {
        case .bitsequence(_): return true
        default: return false
        }
    }
    
    @inlinable func asBytes() -> UInt32? {
        let subtype: TypeDefinition.Weak
        let count: UInt32
        switch flatten().definition {
        case .sequence(of: let type): subtype = type; count = 0
        case .array(count: let c, of: let type): subtype = type; count = c
        default: return nil
        }
        guard case .primitive(is: .u8) = subtype.definition else {
            return nil
        }
        return count
    }
}
