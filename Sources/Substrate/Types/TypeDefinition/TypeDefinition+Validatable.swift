//
//  TypeDefinition+Validatable.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

public extension AnyTypeDefinition {
    @inlinable
    func validate(for: Any.Type, type: TypeDefinition) -> Result<Void, TypeError>
    {
        validate(for: String(describing: `for`), type: type)
    }
    
    @inlinable
    func validate(for: String, type: TypeDefinition) -> Result<Void, TypeError>
    {
        // Maybe we trying to validate the same object
        if objectId == type.objectId { return .success(()) }
        // Nope. Let's validate
        return reduce(with: TypeDefinition.ValidatableReducer(type: `for`),
                      state: [.def(type)], unpack: true).map{_ in}
    }
}

public extension TypeDefinition {
    struct ValidatableReducer: TypeDefinitionReducer {
        public typealias Failure = TypeError
        public typealias State = [Def]
        
        public enum Def {
            case def(TypeDefinition)
            case compact(TypeDefinition)
            case oneType(of: TypeDefinition, count: UInt32, TypeDefinition)
            case oneTypeFields(of: TypeDefinition, [TypeDefinition.Field])
            case variants(of: TypeDefinition, [String: TypeDefinition.Variant])
            case fields(of: TypeDefinition, [TypeDefinition.Field])
            case variantFields(of: TypeDefinition, variant: String, [TypeDefinition.Field])
            
            public var type: TypeDefinition {
                switch self {
                case .def(let def), .fields(of: let def, _), .compact(let def),
                     .oneType(of: let def, count: _, _),
                     .variantFields(of: let def, variant: _, _),
                     .oneTypeFields(of: let def, _), .variants(of: let def, _):
                    return def
                }
            }
        }
        
        public let forType: String
        
        public init(type: Any.Type) {
            self.forType = String(describing: type)
        }
        
        public init(type: String) {
            self.forType = type
        }
        
        @inlinable
        public func start(array def: TypeDefinition, count: UInt32,
                          state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                guard case .def(let type) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Bad element in type stack \(last)",
                                               info: .get()))
                }
                switch type.flatten().definition {
                case .array(count: let rcount, of: let rtype):
                    guard rcount == count else {
                        return .failure(.wrongValuesCount(for: error(state), expected: Int(count),
                                                          type: type.strong, info: .get()))
                    }
                    state.append(.def(rtype))
                    return .success(true)
                case .composite(fields: let fields):
                    guard count == fields.count else {
                        return .failure(.wrongValuesCount(for: error(state), expected: Int(count),
                                                          type: type.strong, info: .get()))
                    }
                    state.append(.oneTypeFields(of: type, fields))
                    return .success(true)
                default:
                    return .failure(.wrongType(for: error(state), type: type.strong,
                                               reason: "Isn't array compatible", info: .get()))
                }
            }
        }
        
        @inlinable
        public func end(array def: TypeDefinition, count: UInt32,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func start(composite def: TypeDefinition, named: Bool,
                          count: Int, state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                guard case .def(let type) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Bad element in type stack \(last)",
                                               info: .get()))
                }
                switch type.flatten().definition {
                case .array(count: let rcount, of: let rtype):
                    guard rcount == count else {
                        return .failure(.wrongValuesCount(for: error(state), expected: count,
                                                          type: type.strong, info: .get()))
                    }
                    state.append(.oneType(of: type, count: rcount, rtype.flatten()))
                    return .success(true)
                case .composite(fields: let fields):
                    guard count == fields.count else {
                        return .failure(.wrongValuesCount(for: error(state), expected: Int(count),
                                                          type: type.strong, info: .get()))
                    }
                    state.append(.fields(of: type, fields))
                    return .success(true)
                default:
                    return .failure(.wrongType(for: error(state), type: type.strong,
                                               reason: "Isn't composite compatible", info: .get()))
                }
            }
        }
        
        @inlinable
        public func end(composite def: TypeDefinition, named: Bool,
                        count: Int, state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func start(variant def: TypeDefinition, count: Int,
                          state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                guard case .def(let type) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Bad element in type stack \(last)",
                                               info: .get()))
                }
                guard case .variant(variants: let vrs) = type.flatten().definition else {
                    return .failure(.wrongType(for: error(state), type: type.strong,
                                               reason: "Isn't variant", info: .get()))
                }
                guard vrs.count == count else {
                    return .failure(.wrongValuesCount(for: error(state), expected: count,
                                                      type: type.strong, info: .get()))
                }
                let vars = Dictionary(uniqueKeysWithValues: vrs.map { ($0.name, $0) })
                state.append(.variants(of: type, vars))
                return .success(true)
            }
        }
        
        @inlinable
        public func end(variant def: TypeDefinition, count: Int,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func start(compact def: TypeDefinition,
                          state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                guard case .def(let type) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Bad element in type stack \(last)",
                                               info: .get()))
                }
                guard case .compact(of: let ctype) = type.flatten().definition else {
                    return .failure(.wrongType(for: error(state), type: type.strong,
                                               reason: "Isn't compact", info: .get()))
                }
                state.append(.compact(ctype))
                return .success(true)
            }
        }
        
        @inlinable
        public func end(compact def: TypeDefinition,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func start(sequence def: TypeDefinition,
                          state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                guard case .def(let type) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Bad element in type stack \(last)",
                                               info: .get()))
                }
                guard case .sequence(of: let stype) = type.flatten().definition else {
                    return .failure(.wrongType(for: error(state), type: type.strong,
                                               reason: "Isn't compact", info: .get()))
                }
                state.append(.def(stype))
                return .success(true)
            }
        }
        
        @inlinable
        public func end(sequence def: TypeDefinition,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func start(field index: Int, name: String?,
                          state: inout State) -> Result<Bool, Failure>
        {
            getStateLast(state: state, .get()).flatMap { last in
                switch last {
                case .fields(of: let type, let fields):
                    guard fields.count > index else {
                        return .failure(.wrongValuesCount(for: error(state),
                                                          expected: index + 1,
                                                          type: type.strong, info: .get()))
                    }
                    state.append(.def(fields[index].type))
                    return .success(true)
                case .oneType(of: let type, count: let count, let otype):
                    guard count > index else {
                        return .failure(.wrongValuesCount(for: error(state),
                                                          expected: index + 1,
                                                          type: type.strong, info: .get()))
                    }
                    state.append(.def(otype))
                    return .success(true)
                case .variantFields(of: let type, variant: let name, let fields):
                    guard fields.count > index else {
                        return .failure(.wrongVariantFieldsCount(for: error(state), variant: name,
                                                                 expected: index + 1, type: type.strong,
                                                                 info: .get()))
                    }
                    state.append(.def(fields[index].type))
                    return .success(true)
                default:
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Isn't composite", info: .get()))
                }
            }
        }
        
        @inlinable
        public func end(field index: Int, name: String?,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func start(variant index: UInt8, name: String,
                          named: Bool, state: inout State) -> Result<Bool, Failure>
        {
            getStateLast(state: state, .get()).flatMap { last in
                guard case .variants(of: let type, let vars) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Isn't variant", info: .get()))
                }
                guard let vrt = vars[name] else {
                    return .failure(.variantNotFound(for: error(state), variant: name,
                                                     type: type, .get()))
                }
                guard vrt.index == index else {
                    return .failure(.wrongVariantIndex(for: error(state), variant: name,
                                                       expected: index, type: type.strong,
                                                       info: .get()))
                }
                state.append(.variantFields(of: type, variant: name, vrt.fields))
                return .success(true)
            }
        }
        
        @inlinable
        public func end(variant index: UInt8, name: String,
                        named: Bool, state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state, .get())
        }
        
        @inlinable
        public func visited(def: TypeDefinition,
                            state: inout State) -> Result<Bool, Failure>
        {
            // recursion. we will check it
            return popState(state: &state, .get())
        }
        
        @inlinable
        public func void(def: TypeDefinition,
                         state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                switch last {
                case .compact(let type), .def(let type):
                    switch type.flatten().definition {
                    case .void: return .success(true)
                    default: return .failure(.wrongType(for: error(state),
                                                        type: type.strong,
                                                        reason: "Isn't void",
                                                        info: .get()))
                    }
                default: return .failure(.wrongType(for: error(state),
                                                    type: last.type.strong,
                                                    reason: "Isn't void",
                                                    info: .get()))
                }
            }
        }
        
        @inlinable
        public func primitive(def: TypeDefinition,
                              is primitive: NetworkType.Primitive,
                              state: inout State) -> Result<Bool, Failure>
        {
            getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                switch last {
                case .def(let type):
                    guard case .primitive(is: let prim) = type.flatten().definition else {
                        return .failure(.wrongType(for: error(state), type: type.strong,
                                                   reason: "Isn't primitive", info: .get()))
                    }
                    return primitive == prim
                        ? .success(true)
                        : .failure(.wrongType(for: error(state), type: type.strong,
                                              reason: "Different primitive. Expected \(primitive)",
                                              info: .get()))
                case .compact(let type):
                    guard case .primitive(is: let prim) = type.flatten().definition else {
                        return .failure(.wrongType(for: error(state), type: type.strong,
                                                   reason: "Isn't primitive compact",
                                                   info: .get()))
                    }
                    guard let suint = primitive.isUInt, let iuint = prim.isUInt else {
                        return .failure(.wrongType(for: error(state), type: type.strong,
                                                   reason: "primitive is not UInt",
                                                   info: .get()))
                    }
                    guard iuint <= suint else {
                        return .failure(.wrongType(for: error(state), type: type.strong,
                                                   reason: "UInt\(suint) can't store\(iuint) bits",
                                                   info: .get()))
                    }
                    return .success(true)
                default:
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Isn't primitive", info: .get()))
                }
            }
        }
        
        @inlinable
        public func bitSequence(def: TypeDefinition, format: BitSequence.Format,
                                state: inout State) -> Result<Bool, Failure>
        {
            return getStateLastMaybeOneTypeFields(state: state, .get()) { last in
                guard case .def(let type) = last else {
                    return .failure(.wrongType(for: error(state), type: last.type.strong,
                                               reason: "Bad element in type stack \(last)",
                                               info: .get()))
                }
                guard case .bitsequence(format: let iformat) = type.flatten().definition else {
                    return .failure(.wrongType(for: error(state), type: type.strong,
                                               reason: "Isn't bit sequence", info: .get()))
                }
                return format == iformat
                    ? .success(true)
                    : .failure(.wrongType(for: error(state), type: type.strong,
                                          reason: "Format is different. Expected \(format)",
                                          info: .get()))
            }
        }
        
        public func error(_ state: State) -> String {
            state.reduce(into: forType) { res, elem in
                res += ".\(elem.type.name)"
            }
        }
        
        @inlinable
        public func getStateLastMaybeOneTypeFields(
            state: State, _ info: ErrorMethodInfo,
            cb: (Def) -> Result<Bool, Failure>
        ) -> Result<Bool, Failure> {
            getStateLast(state: state, info).flatMap { last in
                if case .oneTypeFields(of: _, let fields) = last {
                    for field in fields {
                        switch cb(.def(field.type)) {
                        case .failure(let err): return .failure(err)
                        case .success(let f): if !f { return .success(false) }
                        }
                    }
                }
                return cb(last)
            }
        }
        
        @inlinable
        public func getStateLast(state: State, _ info: ErrorMethodInfo) -> Result<Def, Failure> {
            guard let last = state.last else {
                return .failure(.badState(for: forType,
                                          reason: "No elements in type stack",
                                          info: info))
            }
            return .success(last)
        }
        
        @inlinable
        public func popState(state: inout State, _ info: ErrorMethodInfo) -> Result<Bool, Failure> {
            guard state.count > 0 else {
                return .failure(.badState(for: forType,
                                          reason: "No elements in type stack",
                                          info: info))
            }
            state.removeLast()
            return .success(true)
        }
    }
}
