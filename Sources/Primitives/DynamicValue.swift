//
//  DynamicValue.swift
//  
//
//  Created by Yehor Popovych on 1/6/21.
//

import Foundation
import ScaleCodec

// TODO: Create better dynamic logic (DYNAMIC)
public indirect enum DValue: Error {
    case null
    case native(type: DType, value: ScaleDynamicCodable)
    case collection(values: [DValue])
    case map(values: [(key: DValue, value: DValue)])
    case result(res: Result<DValue, DValue>)
    
    public init<T: ScaleDynamicCodable>(native: T, registry: TypeRegistryProtocol) throws {
        let type = try registry.type(of: T.self)
        self = .native(type: type, value: native)
    }
}

public extension DValue {
    var dynamicEncodable: ScaleDynamicEncodable {
        switch self {
        case .null: return DNull()
        case .native(type: _, value: let v): return v
        case .collection(values: let values):
            return DEncodableCollection(values.map { $0.dynamicEncodable })
        case .map(values: let values):
            return DEncodableMap(values.map { (key: $0.key.dynamicEncodable, value: $0.value.dynamicEncodable) })
        case .result(res: let res):
            switch res {
            case .failure(let err): return DEncodableEither.right(val: err.dynamicEncodable)
            case .success(let val): return DEncodableEither.left(val: val.dynamicEncodable)
            }
        }
    }
}

public struct DEncodableCollection: ScaleDynamicEncodable, ScaleDynamicEncodableCollectionConvertible {
    public let array: Array<ScaleDynamicEncodable>
    
    public init(_ array: [ScaleDynamicEncodable]) {
        self.array = array
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try array.encode(in: encoder) { val, encoder in
            try val.encode(in: encoder, registry: registry)
        }
    }
    
    public var encodableCollection: DEncodableCollection { self }
}

public struct DEncodableMap: ScaleDynamicEncodable, ScaleDynamicEncodableMapConvertible {
    public let map: Array<(key: ScaleDynamicEncodable, value: ScaleDynamicEncodable)>
    
    public init(_ array: [(key: ScaleDynamicEncodable, value: ScaleDynamicEncodable)]) {
        self.map = array
    }
    
    public init<K, V>(_ dict: Dictionary<K, V>)
        where K: ScaleDynamicEncodable & Hashable, V: ScaleDynamicEncodable
    {
        self.map = Array(dict)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try map.encode(in: encoder) { val, encoder in
            try val.key.encode(in: encoder, registry: registry)
            try val.value.encode(in: encoder, registry: registry)
        }
    }
    
    public var encodableMap: DEncodableMap { self }
}

public enum DEncodableEither: ScaleDynamicEncodable, ScaleDynamicEncodableEitherConvertible {
    case left(val: ScaleDynamicEncodable)
    case right(val: ScaleDynamicEncodable)
    
    public init<S, E>(_ res: Result<S, E>)
        where S: ScaleDynamicEncodable, E: ScaleDynamicEncodable & Error
    {
        switch res {
        case .failure(let err): self = .right(val: err)
        case .success(let val): self = .left(val: val)
        }
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let result: Result<DNull, DNull>
        let value: ScaleDynamicEncodable
        switch self {
        case .left(val: let val):
            value = val
            result = .success(DNull())
        case .right(val: let val):
            value = val
            result = .failure(DNull())
        }
        try result.encode(
            in: encoder,
            lwriter: { _, encoder in
                try value.encode(in: encoder, registry: registry)
            },
            rwriter: { _, encoder in
                try value.encode(in: encoder, registry: registry)
            }
        )
    }
    
    public var encodableEither: DEncodableEither { self }
}

public enum DEncodableOptional: ScaleDynamicEncodable, ScaleDynamicEncodableOptionalConvertible {
    case none
    case some(ScaleDynamicEncodable)
    
    public init(_ optional: Optional<ScaleDynamicEncodable>) {
        switch optional {
        case .none: self = .none
        case .some(let val): self = .some(val)
        }
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        let optional: Optional<DNull>
        let value: ScaleDynamicEncodable?
        switch self {
        case .none:
            optional = nil
            value = nil
        case .some(let val):
            optional = DNull()
            value = val
        }
        try optional.encode(in: encoder) { _, encoder in
            try value!.encode(in: encoder, registry: registry)
        }
    }
    
    public var optional: Optional<ScaleDynamicEncodable> {
        switch self {
        case .none: return .none
        case .some(let val): return .some(val)
        }
    }
    
    public var encodableOptional: DEncodableOptional { self }
}
