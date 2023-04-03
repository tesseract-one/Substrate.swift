//
//  Value+Decodable.swift
//  
//
//  Created by Yehor Popovych on 28.03.2023.
//

import Foundation

extension Value where C == RuntimeTypeId {
    public init(from decoder: Decoder, `as` type: RuntimeTypeId, registry: Registry) throws {
        var value = ValueDecodingContainer(decoder)
        try self.init(from: &value, as: type, registry: registry)
    }
    
    public init(from container: inout ValueDecodingContainer,
                `as` type: RuntimeTypeId,
                registry: Registry) throws
    {
        guard let typeInfo = registry.resolve(type: type) else {
            throw DecodingError.typeNotFound(type)
        }
        switch typeInfo.definition {
        case .composite(fields: let fields):
            self = try Self._decodeComposite(from: &container, type: type, fields: fields, registry: registry)
        case .sequence(of: let vType):
            self = try Self._decodeSequence(from: &container, type: type, valueType: vType, registry: registry)
        case .variant(variants: let vars):
            self = try Self._decodeVariant(from: &container, path: typeInfo.pathBasedName, type: type, variants: vars, registry: registry)
        }
    }
}

public enum ValueDecodingContainer {
    case decoder(Decoder)
    case single(SingleValueDecodingContainer)
    case unkeyed(UnkeyedDecodingContainer)
    case keyed(AnyCodableCodingKey, KeyedDecodingContainer<AnyCodableCodingKey>)
    
    public init(_ decoder: Decoder) {
        self = .decoder(decoder)
    }
    
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        switch self {
        case .decoder(let decoder):
            self = try .single(decoder.singleValueContainer())
            return try self.decode(type)
        case .single(var container): return try container.decode(type)
        case .keyed(let key, var container): return try container.decode(type, forKey: key)
        case .unkeyed(var container): return try container.decode(type)
        }
    }
    
    mutating func decodeNil() throws -> Bool {
        switch self {
        case .decoder(let decoder):
            self = try .single(decoder.singleValueContainer())
            return try self.decodeNil()
        case .single(var container): return container.decodeNil()
        case .keyed(let key, var container): return try container.decodeNil(forKey: key)
        case .unkeyed(var container): return try container.decodeNil()
        }
    }
    
    mutating func nestedUnkeyedContainer() throws -> Self {
        switch self {
        case .decoder(let decoder):
            let container = try decoder.unkeyedContainer()
            self = .unkeyed(container)
            return self
        case .single(var container):
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "SingleValueContainer asked for nested")
        case .unkeyed(var container): return try .unkeyed(container.nestedUnkeyedContainer())
        case .keyed(let key, var container): return try .unkeyed(container.nestedUnkeyedContainer(forKey: key))
        }
    }
    
    mutating func nestedKeyedContainer() throws -> Self {
        let emptyKey = AnyCodableCodingKey(0)
        switch self {
        case .decoder(let decoder):
            let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
            self = .keyed(emptyKey, container)
            return self
        case .single(var container):
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "SingleValueContainer asked for nested")
        case .unkeyed(var container):
            return try .keyed(emptyKey, container.nestedContainer(keyedBy: AnyCodableCodingKey.self))
        case .keyed(let key, var container):
            return try .keyed(emptyKey, container.nestedContainer(keyedBy: AnyCodableCodingKey.self, forKey: key))
        }
    }
    
    mutating func nextKey(key: String) throws {
        switch self {
        case .keyed(_, let container):
            self = .keyed(AnyCodableCodingKey(key), container)
        default: throw try newError("NextKey: not a keyed container")
        }
    }
    
    func isAtEnd() throws -> Bool {
        switch self {
        case .unkeyed(let container): return container.isAtEnd
        default: throw try newError("isAtEnd: not an unkeyed container")
        }
    }
    
    func count() -> Int? {
        switch self {
        case .unkeyed(let container): return container.count
        default: return nil
        }
    }
    
    func newError(_ description: String) throws -> DecodingError {
        switch self {
        case .decoder(let decoder):
            let container = try decoder.singleValueContainer()
            return DecodingError.dataCorruptedError(in: container, debugDescription: description)
        case .single(let container):
            return DecodingError.dataCorruptedError(in: container, debugDescription: description)
        case .unkeyed(let container):
            return DecodingError.dataCorruptedError(in: container, debugDescription: description)
        case .keyed(let key, let container):
            return DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: description)
        }
    }
}

private extension Value where C == RuntimeTypeId {
    static func _decodeComposite(
        from: inout ValueDecodingContainer, type: RuntimeTypeId, fields: [RuntimeTypeField], registry: Registry
    ) throws -> Self {
        guard fields.count > 0 else {
            guard try from.decodeNil() else {
                throw try from.newError("Expected nil value")
            }
            return Value(value: .sequence([]), context: type)
        }
        if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: registry.decoder(with: data), as: type, registry: registry)
        } else if fields[0].name != nil { // Map
            var value = try from.nestedKeyedContainer()
            var map: [String: Value<C>] = Dictionary(minimumCapacity: fields.count)
            for field in fields {
                try value.nextKey(key: field.name!)
                map[field.name!] = try Value(from: &value,
                                             as: field.type,
                                             registry: registry)
            }
            return Value(value: .map(map), context: type)
        } else { // Sequence
            var value = try from.nestedUnkeyedContainer()
            let seq = try fields.map {
                try Value(from: &value, as: $0.type, registry: registry)
            }
            return Value(value: .sequence(seq), context: type)
        }
    }
    
    static func _decodeSequence(
        from: inout ValueDecodingContainer, type: RuntimeTypeId, valueType: RuntimeTypeId, registry: Registry
    ) throws -> Self {
        guard let vTypeInfo = registry.resolve(type: valueType) else {
            throw DecodingError.typeNotFound(valueType)
        }
        if case .primitive(is: .u8) = vTypeInfo.definition { // [u8] array
            if let data = try? from.decode(Data.self) {
                return Value(value: .primitive(.bytes(data)), context: type)
            } else if let data = try? from.decode([UInt8].self) {
                return Value(value: .primitive(.bytes(Data(data))), context: type)
            } else {
                throw try from.newError("Expected hex or [u8] for data")
            }
        } else if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: registry.decoder(with: data), as: type, registry: registry)
        } else { // array
            var value = try from.nestedUnkeyedContainer()
            var values = Array<Self>()
            if let count = value.count() {
                values.reserveCapacity(count)
            }
            while try !value.isAtEnd() {
                values.append(try Value(from: &value, as: valueType, registry: registry))
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodeVariant(
        from: inout ValueDecodingContainer, path: String?, type: RuntimeTypeId,
        variants: [RuntimeTypeVariantItem], registry: Registry
    ) throws -> Self {
        guard path != "Option" else {
            let someType = variants.first(where: { $0.name == "Some" })!.fields[0].type
            if try from.decodeNil() {
                return Value(value: .variant(.sequence(name: "None", values: [])), context: type)
            }
            return try Self._decodeComposite(from: &from, type: someType, fields: <#T##[RuntimeTypeField]#>, registry: <#T##Registry#>)
        }
        if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: registry.decoder(with: data), as: type, registry: registry)
        } else {
            
        }
//        let index = try decoder.decode(.enumCaseId)
//        guard let variant = variants.first(where: { $0.index == index }) else {
//            throw DecodingError.variantNotFound(index, type)
//        }
//        let composite = try _decodeComposite(from: decoder, type: type, fields: variant.fields, registry: registry)
//        if let map = composite.map {
//            return Value(value: .variant(.map(name: variant.name, fields: map)), context: type)
//        }
//        return Value(value: .variant(.sequence(name: variant.name, values: composite.sequence!)), context: type)
    }
    
    static func _decodeOption(
        from: inout ValueDecodingContainer, type: RuntimeTypeId, registry: Registry
    ) throws -> Self {
        
        let index = try decoder.decode(.enumCaseId)
        guard let variant = variants.first(where: { $0.index == index }) else {
            throw DecodingError.variantNotFound(index, type)
        }
        let composite = try _decodeComposite(from: decoder, type: type, fields: variant.fields, registry: registry)
        if let map = composite.map {
            return Value(value: .variant(.map(name: variant.name, fields: map)), context: type)
        }
        return Value(value: .variant(.sequence(name: variant.name, values: composite.sequence!)), context: type)
    }
}
