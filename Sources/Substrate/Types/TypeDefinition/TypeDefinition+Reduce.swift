//
//  TypeDefinition+Reduce.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

public protocol TypeDefinitionReducer {
    associatedtype Failure: Error
    associatedtype State
    
    func start(array def: TypeDefinition, count: UInt32,
               state: inout State) -> Result<Bool, Failure>
    func start(composite def: TypeDefinition, named: Bool,
               count: Int, state: inout State) -> Result<Bool, Failure>
    func start(variant def: TypeDefinition, count: Int,
               state: inout State) -> Result<Bool, Failure>
    func start(compact def: TypeDefinition, state: inout State) -> Result<Bool, Failure>
    func start(sequence def: TypeDefinition, state: inout State) -> Result<Bool, Failure>
    
    func start(field index: Int, name: String?,
               state: inout State) -> Result<Bool, Failure>
    func start(variant index: UInt8, name: String,
               named: Bool, state: inout State) -> Result<Bool, Failure>
    
    func end(array def: TypeDefinition, count: UInt32,
             state: inout State) -> Result<Bool, Failure>
    func end(composite def: TypeDefinition, named: Bool,
             count: Int, state: inout State) -> Result<Bool, Failure>
    func end(variant def: TypeDefinition, count: Int,
             state: inout State) -> Result<Bool, Failure>
    func end(compact def: TypeDefinition, state: inout State) -> Result<Bool, Failure>
    func end(sequence def: TypeDefinition, state: inout State) -> Result<Bool, Failure>
    
    func end(field index: Int, name: String?, state: inout State) -> Result<Bool, Failure>
    func end(variant index: UInt8, name: String,
             named: Bool, state: inout State) -> Result<Bool, Failure>
    
    func visited(def: TypeDefinition, state: inout State) -> Result<Bool, Failure>
    
    func void(def: TypeDefinition, state: inout State) -> Result<Bool, Failure>
    func primitive(def: TypeDefinition, is primitive: NetworkType.Primitive,
                   state: inout State) -> Result<Bool, Failure>
    func bitSequence(def: TypeDefinition, format: BitSequence.Format,
                     state: inout State) -> Result<Bool, Failure>
}

public extension AnyTypeDefinition {
    @inlinable
    func reduce<R: TypeDefinitionReducer>(
        with reducer: R, state: R.State, unpack: Bool = false
    ) -> Result<R.State, R.Failure> {
        var state = state
        return reduce(with: reducer, state: &state,
                      unpack: unpack).map { state }
    }
    
    @inlinable
    func reduce<R: TypeDefinitionReducer>(
        with reducer: R, state: inout R.State, unpack: Bool = false
    ) -> Result<Void, R.Failure> {
        var visited = Dictionary<ObjectIdentifier, TypeDefinition.Weak>()
        return reduce(with: reducer, state: &state, unpack: unpack,
                      visited: &visited).map {_ in}
            
    }
    
    func reduce<R: TypeDefinitionReducer>(
        with reducer: R, state: inout R.State, unpack: Bool,
        visited: inout Dictionary<ObjectIdentifier, TypeDefinition.Weak>
    ) -> Result<Bool, R.Failure> {
        let id = self.objectId
        if let visit = visited[id] {
            return reducer.visited(def: *visit, state: &state)
        }
        visited[id] = self.weak; defer { let _ = visited.removeValue(forKey: id) }
        switch definition {
        case .composite(fields: let fields):
            // unpack 1 field composite
            if unpack && fields.count == 1 {
                return fields[0].type.reduce(with: reducer, state: &state,
                                             unpack: unpack, visited: &visited)
            }
            let named = fields.firstIndex { $0.name != nil } != nil
            switch reducer.start(composite: self.strong, named: named,
                                 count: fields.count, state: &state)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch reduce(fields: fields, with: reducer,
                          state: &state, unpack: unpack, visited: &visited)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch reducer.end(composite: self.strong, named: named,
                               count: fields.count, state: &state)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .variant(variants: let variants):
            switch reducer.start(variant: self.strong, count: variants.count,
                                 state: &state)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            for vart in variants {
                let named = vart.fields.firstIndex { $0.name != nil } != nil
                switch reducer.start(variant: vart.index, name: vart.name,
                                     named: named, state: &state)
                {
                case .failure(let err): return .failure(err)
                case .success(let finish): if !finish { return .success(false) }
                }
                switch reduce(fields: vart.fields, with: reducer,
                              state: &state, unpack: unpack, visited: &visited)
                {
                case .failure(let err): return .failure(err)
                case .success(let finish): if !finish { return .success(false) }
                }
                switch reducer.end(variant: vart.index, name: vart.name,
                                   named: named, state: &state)
                {
                case .failure(let err): return .failure(err)
                case .success(let finish): if !finish { return .success(false) }
                }
            }
            switch reducer.end(variant: self.strong, count: variants.count,
                               state: &state)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .array(count: let count, of: let value):
            switch reducer.start(array: self.strong, count: count, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch value.reduce(with: reducer, state: &state,
                                unpack: unpack, visited: &visited)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch reducer.end(array: self.strong, count: count, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .compact(of: let value):
            switch reducer.start(compact: self.strong, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch value.reduce(with: reducer, state: &state,
                                unpack: unpack, visited: &visited)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch reducer.end(compact: self.strong, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .sequence(of: let value):
            switch reducer.start(sequence: self.strong, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch value.reduce(with: reducer, state: &state,
                                unpack: unpack, visited: &visited)
            {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch reducer.end(sequence: self.strong, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .primitive(is: let prim):
            switch reducer.primitive(def: self.strong, is: prim, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .bitsequence(format: let format):
            switch reducer.bitSequence(def: self.strong, format: format, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        case .void:
            switch reducer.void(def: self.strong, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        }
        return .success(true)
    }
    
    @inlinable
    func reduce<R: TypeDefinitionReducer>(
        fields: [TypeDefinition.Field], with reducer: R, state: inout R.State,
        unpack: Bool, visited: inout Dictionary<ObjectIdentifier, TypeDefinition.Weak>
    ) -> Result<Bool, R.Failure> {
        for (idx, field) in fields.enumerated() {
            switch reducer.start(field: idx, name: field.name, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            let result = field.type.reduce(with: reducer, state: &state,
                                           unpack: unpack, visited: &visited)
            switch result {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
            switch reducer.end(field: idx, name: field.name, state: &state) {
            case .failure(let err): return .failure(err)
            case .success(let finish): if !finish { return .success(false) }
            }
        }
        return .success(true)
    }
}
