//
//  TypeDefinition+Description.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

public extension TypeDefinition {
    struct DescriptionReducer: TypeDefinitionReducer {
        public typealias Failure = Never
        public typealias State = String
        
        @inlinable
        public func start(array def: TypeDefinition, count: UInt32,
                          state: inout String) -> Result<Bool, Never>
        {
            state += "\(def.fullName)[\(count); "
            return .success(true)
        }
        
        @inlinable
        public func end(array def: TypeDefinition, count: UInt32,
                        state: inout String) -> Result<Bool, Never>
        {
            state += "]"
            return .success(true)
        }
        
        @inlinable
        public func start(composite def: TypeDefinition, named: Bool,
                          count: Int, state: inout String) -> Result<Bool, Never>
        {
            state += named ? "\(def.fullName){" : "\(def.fullName)("
            return .success(true)
        }
        
        @inlinable
        public func end(composite def: TypeDefinition, named: Bool,
                        count: Int, state: inout String) -> Result<Bool, Never>
        {
            state += named ? "}" : ")"
            return .success(true)
        }
        
        @inlinable
        public func start(variant def: TypeDefinition, count: Int,
                          state: inout String) -> Result<Bool, Never>
        {
            state += "\(def.fullName)("
            return .success(true)
        }
        
        @inlinable
        public func end(variant def: TypeDefinition, count: Int,
                        state: inout String) -> Result<Bool, Never>
        {
            state += ")"
            return .success(true)
        }
        
        @inlinable
        public func start(compact def: TypeDefinition,
                          state: inout String) -> Result<Bool, Never>
        {
            state += "%"
            return .success(true)
        }
        
        @inlinable
        public func end(compact def: TypeDefinition,
                        state: inout String) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        @inlinable
        public func start(sequence def: TypeDefinition,
                          state: inout String) -> Result<Bool, Never>
        {
            state += "["
            return .success(true)
        }
        
        @inlinable
        public func end(sequence def: TypeDefinition,
                        state: inout String) -> Result<Bool, Never>
        {
            state += "]"
            return .success(true)
        }
        
        @inlinable
        public func start(field index: Int, name: String?,
                          state: inout String) -> Result<Bool, Never>
        {
            state += "\(index > 0 ? ", " : "")\(name != nil ? "\(name!): " : "")"
            return .success(true)
        }
        
        @inlinable
        public func end(field index: Int, name: String?,
                        state: inout String) -> Result<Bool, Never>
        {
            return .success(true)
        }
        
        @inlinable
        public func start(variant index: UInt8, name: String,
                          named: Bool, state: inout String) -> Result<Bool, Never>
        {
            state += "\(index > 0 ? ", " : "")\(name)\(named ? "{" : "(")"
            return .success(true)
        }
        
        @inlinable
        public func end(variant index: UInt8, name: String,
                        named: Bool, state: inout String) -> Result<Bool, Never>
        {
            state += named ? "}" : ")"
            return .success(true)
        }
        
        @inlinable
        public func visited(def: TypeDefinition,
                            state: inout String) -> Result<Bool, Never>
        {
            state += "&\(def.fullName)"
            return .success(true)
        }
        
        @inlinable
        public func void(def: TypeDefinition,
                         state: inout String) -> Result<Bool, Never>
        {
            state += "\(def.fullName)()"
            return .success(true)
        }
        
        @inlinable
        public func primitive(def: TypeDefinition,
                              is primitive: NetworkType.Primitive,
                              state: inout String) -> Result<Bool, Never> {
            state += primitive.description
            return .success(true)
        }
        
        @inlinable
        public func bitSequence(def: TypeDefinition, format: BitSequence.Format,
                                state: inout String ) -> Result<Bool, Never>
        {
            state += "\(def.name)<\(format)>"
            return .success(true)
        }
    }
}

public extension AnyTypeDefinition {
    var description: String {
        var state = ""
        let _ = self.reduce(with: TypeDefinition.DescriptionReducer(), state: &state)
        return state
    }
}
