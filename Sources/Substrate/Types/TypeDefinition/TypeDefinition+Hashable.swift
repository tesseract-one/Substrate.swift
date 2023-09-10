//
//  TypeDefinition+Hashable.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

public extension TypeDefinition {
    struct HashableReducer: TypeDefinitionReducer {
        public typealias Failure = Never
        public typealias State = Swift.Hasher
        
        public func start(array def: TypeDefinition,
                          count: UInt32,
                          state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            state.combine(count)
            return .success(true)
        }
        
        public func start(composite def: TypeDefinition, named: Bool,
                          count: Int, state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            state.combine(named)
            state.combine(count)
            return .success(true)
        }
        
        public func start(variant def: TypeDefinition, count: Int,
                          state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            state.combine(count)
            return .success(true)
        }
        
        public func start(compact def: TypeDefinition,
                          state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            return .success(true)
        }
        
        public func start(sequence def: TypeDefinition,
                          state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            return .success(true)
        }
        
        public func start(field index: Int, name: String?,
                          state: inout State) -> Result<Bool, Never>
        {
            state.combine(index)
            state.combine(name)
            return .success(true)
        }
        
        public func start(variant index: UInt8, name: String,
                          named: Bool, state: inout State) -> Result<Bool, Never>
        {
            state.combine(index)
            state.combine(name)
            state.combine(named)
            return .success(true)
        }
        
        public func end(array def: TypeDefinition, count: UInt32,
                        state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func end(composite def: TypeDefinition, named: Bool,
                        count: Int, state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func end(variant def: TypeDefinition, count: Int,
                        state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func end(compact def: TypeDefinition,
                        state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func end(sequence def: TypeDefinition,
                        state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func end(field index: Int, name: String?,
                        state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func end(variant index: UInt8, name: String,
                        named: Bool, state: inout State) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        public func visited(def: TypeDefinition,
                            state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            return .success(true)
        }
        
        public func void(def: TypeDefinition,
                         state: inout State) -> Result<Bool, Never>
        {
            state.combine(def.name)
            state.combine(def.parameters)
            state.combine(UInt.max)
            return .success(true)
        }
        
        public func primitive(def: TypeDefinition,
                              is primitive: NetworkType.Primitive,
                              state: inout State) -> Result<Bool, Never>
        {
            state.combine(primitive)
            return .success(true)
        }
        
        public func bitSequence(def: TypeDefinition, format: BitSequence.Format,
                                state: inout State) -> Result<Bool, Never>
        {
            state.combine(format)
            return .success(true)
        }
    }
}

public extension AnyTypeDefinition {
    func hash(into hasher: inout Swift.Hasher) {
        let _ = reduce(with: TypeDefinition.HashableReducer(), state: &hasher)
    }
}
