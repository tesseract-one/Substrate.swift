//
//  TypeDefinition+Equatable.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

public extension TypeDefinition {
    struct EquatableReducer: TypeDefinitionReducer {
        public struct Failure: Error {
            public init() {}
            @inlinable public static var ne: Self { Self() }
        }
        public typealias State = [Def]
        
        public enum Def {
            case def(TypeDefinition.Def)
            case fields([TypeDefinition.Field])
            case variants([UInt8: TypeDefinition.Variant])
        }
        
        @inlinable
        public func start(array def: TypeDefinition, count: UInt32,
                          state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.array(count: let rc, of: let rd)) = last,
                  rc == count else { return .failure(.ne) }
            state.append(.def(rd.definition))
            return .success(true)
        }
        
        @inlinable
        public func end(array def: TypeDefinition, count: UInt32,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func start(composite def: TypeDefinition, named: Bool,
                          count: Int, state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.composite(fields: let fds)) = last,
                  fds.count == count else { return .failure(.ne) }
            state.append(.fields(fds))
            return .success(true)
        }
        
        @inlinable
        public func end(composite def: TypeDefinition, named: Bool,
                        count: Int, state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func start(variant def: TypeDefinition, count: Int,
                          state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.variant(variants: let vrs)) = last,
                  vrs.count == count else { return .failure(.ne) }
            let vars = Dictionary(uniqueKeysWithValues: vrs.map { ($0.index, $0) })
            state.append(.variants(vars))
            return .success(true)
        }
        
        @inlinable
        public func end(variant def: TypeDefinition, count: Int,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func start(compact def: TypeDefinition,
                          state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.compact(of: let def)) = last
                  else { return .failure(.ne) }
            state.append(.def(def.definition))
            return .success(true)
        }
        
        @inlinable
        public func end(compact def: TypeDefinition,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func start(sequence def: TypeDefinition,
                          state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.sequence(of: let def)) = last
                  else { return .failure(.ne) }
            state.append(.def(def.definition))
            return .success(true)
        }
        
        @inlinable
        public func end(sequence def: TypeDefinition,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func start(field index: Int, name: String?,
                          state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .fields(let fds) = last, fds.count > index,
                  fds[index].name == name else { return .failure(.ne) }
            state.append(.def(fds[index].type.definition))
            return .success(true)
        }
        
        @inlinable
        public func end(field index: Int, name: String?,
                        state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func start(variant index: UInt8, name: String,
                          named: Bool, state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .variants(let vars) = last,
                  let vrt = vars[index],
                  vrt.name == name else { return .failure(.ne) }
            state.append(.fields(vrt.fields))
            return .success(true)
        }
        
        @inlinable
        public func end(variant index: UInt8, name: String,
                        named: Bool, state: inout State) -> Result<Bool, Failure>
        {
            popState(state: &state)
        }
        
        @inlinable
        public func visited(def: TypeDefinition,
                            state: inout State) -> Result<Bool, Failure>
        {
            return .success(true)
        }
        
        @inlinable
        public func void(def: TypeDefinition,
                         state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.void) = last else { return .failure(.ne) }
            return .success(true)
        }
        
        @inlinable
        public func primitive(def: TypeDefinition,
                              is primitive: NetworkType.Primitive,
                              state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.primitive(is: let p)) = last,
                  primitive == p else { return .failure(.ne) }
            return .success(true)
        }
        
        @inlinable
        public func bitSequence(def: TypeDefinition, format: BitSequence.Format,
                                state: inout State) -> Result<Bool, Failure>
        {
            guard let last = state.last,
                  case .def(.bitsequence(format: let fmt)) = last,
                  fmt == format else { return .failure(.ne) }
            return .success(true)
        }
        
        @inlinable
        public func popState(state: inout State) -> Result<Bool, Failure> {
            guard state.count > 0 else { return .failure(.ne) }
            state.removeLast()
            return .success(true)
        }
    }
}

public extension AnyTypeDefinition {
    static func == (lhs: Self, rhs: Self) -> Bool {
        // quick storage pointer test
        if lhs.objectId == rhs.objectId { return true }
        // different objects. full test
        var state: [TypeDefinition.EquatableReducer.Def] = [.def(rhs.definition)]
        do {
            try lhs.reduce(with: TypeDefinition.EquatableReducer(), state: &state).get()
            return true
        } catch { return false }
    }
}
