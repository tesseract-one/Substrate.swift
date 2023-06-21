//
//  Value+Decodable.swift
//  
//
//  Created by Yehor Popovych on 28.03.2023.
//

import Foundation
import ScaleCodec

extension Value: RuntimeDynamicDecodable where C == RuntimeTypeId {
    public init(from decoder: Decoder, `as` type: RuntimeTypeId) throws {
        var value = ValueDecodingContainer(decoder)
        try self.init(from: &value, as: type, runtime: decoder.runtime)
    }
    
    
}
extension Value where C == RuntimeTypeId {
    public init(from container: inout ValueDecodingContainer,
                `as` type: RuntimeTypeId,
                runtime: Runtime) throws
    {
        guard let typeInfo = runtime.resolve(type: type) else {
            throw DecodingError.typeNotFound(type)
        }
        switch typeInfo.definition {
        case .composite(fields: let fields):
            self = try Self._decodeComposite(from: &container, type: type, fields: fields, runtime: runtime)
        case .sequence(of: let vType):
            self = try Self._decodeSequence(from: &container, type: type, valueType: vType, runtime: runtime)
        case .variant(variants: let vars):
            self = try Self._decodeVariant(from: &container, path: typeInfo.pathBasedName,
                                           type: type, variants: vars, runtime: runtime)
        case .array(count: let count, of: let vType):
            self = try Self._decodeArray(from: &container, type: type, count: count,
                                         valueType: vType, runtime: runtime)
        case .tuple(components: let fields):
            self = try Self._decodeTuple(from: &container, type: type, fields: fields, runtime: runtime)
        case .primitive(is: let vType):
            self = try Self._decodePrimitive(from: &container, type: type, prim: vType, runtime: runtime)
        case .compact(of: let vType):
            self = try Self._decodeCompact(from: &container, type: type, of: vType, runtime: runtime)
        case .bitsequence(store: let store, order: let order):
            self = try Self._decodeBitSequence(from: &container, type: type, store: store,
                                               order: order, runtime: runtime)
        }
    }
}

public enum ValueDecodingContainer {
    case decoder(Decoder)
    case unkeyed(UnkeyedDecodingContainer)
    case keyed(AnyCodableCodingKey, KeyedDecodingContainer<AnyCodableCodingKey>)
    
    public init(_ decoder: Decoder) {
        self = .decoder(decoder)
    }
    
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        switch self {
        case .decoder(let decoder): return try decoder.singleValueContainer().decode(type)
        case .keyed(let key, let container): return try container.decode(type, forKey: key)
        case .unkeyed(var container):
            let val = try container.decode(type)
            self = .unkeyed(container)
            return val
        }
    }
    
    mutating func decodeNil() throws -> Bool {
        switch self {
        case .decoder(let decoder): return try decoder.singleValueContainer().decodeNil()
        case .keyed(let key, let container): return try container.decodeNil(forKey: key)
        case .unkeyed(var container):
            let val = try container.decodeNil()
            self = .unkeyed(container)
            return val
        }
    }
    
    mutating func nestedUnkeyedContainer() throws -> Self {
        switch self {
        case .decoder(let decoder): return try .unkeyed(decoder.unkeyedContainer())
        case .keyed(let key, let container): return try .unkeyed(container.nestedUnkeyedContainer(forKey: key))
        case .unkeyed(var container):
            let nested = try container.nestedUnkeyedContainer()
            self = .unkeyed(container)
            return .unkeyed(nested)
        }
    }
    
    mutating func nestedKeyedContainer() throws -> Self {
        let emptyKey = AnyCodableCodingKey(0)
        switch self {
        case .decoder(let decoder):
            return try .keyed(emptyKey, decoder.container(keyedBy: AnyCodableCodingKey.self))
        case .keyed(let key, let container):
            return try .keyed(emptyKey, container.nestedContainer(keyedBy: AnyCodableCodingKey.self, forKey: key))
        case .unkeyed(var container):
            let nested = try container.nestedContainer(keyedBy: AnyCodableCodingKey.self)
            self = .unkeyed(container)
            return .keyed(emptyKey, nested)
        }
    }
    
    mutating func next(key: String) throws {
        switch self {
        case .keyed(_, let container):
            self = .keyed(AnyCodableCodingKey(key), container)
        default: throw try newError("next(key:): not a keyed container")
        }
    }
    
    func contains(key: String) throws -> Bool {
        switch self {
        case .keyed(_, let container):
            return container.contains(AnyCodableCodingKey(key))
        default: throw try newError("contains(key:): not a keyed container")
        }
    }
    
    func isAtEnd() throws -> Bool {
        switch self {
        case .unkeyed(let container): return container.isAtEnd
        default: throw try newError("isAtEnd: not an unkeyed container")
        }
    }
    
    func count() throws -> Int? {
        switch self {
        case .unkeyed(let container): return container.count
        default: throw try newError("count: not an unkeyed container")
        }
    }
    
    func newError(_ description: String) throws -> DecodingError {
        switch self {
        case .decoder(let decoder):
            let container = try decoder.singleValueContainer()
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
        from: inout ValueDecodingContainer, type: RuntimeTypeId,
        fields: [RuntimeTypeField], runtime: Runtime
    ) throws -> Self {
        guard fields.count > 0 else {
            guard try from.decodeNil() else {
                throw try from.newError("Expected nil value")
            }
            return Value(value: .sequence([]), context: type)
        }
        if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: runtime.decoder(with: data), as: type, runtime: runtime)
        } else if fields[0].name != nil { // Map
            var value = try from.nestedKeyedContainer()
            var map: [String: Value<C>] = Dictionary(minimumCapacity: fields.count)
            for field in fields {
                try value.next(key: field.name!.camelCased(with: "_"))
                map[field.name!] = try Value(from: &value, as: field.type, runtime: runtime)
            }
            return Value(value: .map(map), context: type)
        } else { // Sequence
            var value = try from.nestedUnkeyedContainer()
            let seq = try fields.map {
                try Value(from: &value, as: $0.type, runtime: runtime)
            }
            return Value(value: .sequence(seq), context: type)
        }
    }
    
    static func _decodeSequence(
        from: inout ValueDecodingContainer, type: RuntimeTypeId,
        valueType: RuntimeTypeId, runtime: Runtime
    ) throws -> Self {
        guard let vTypeInfo = runtime.resolve(type: valueType) else {
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
            return try Value(from: runtime.decoder(with: data), as: type, runtime: runtime)
        } else { // array
            var value = try from.nestedUnkeyedContainer()
            var values = Array<Self>()
            if let count = try value.count() {
                values.reserveCapacity(count)
            }
            while try !value.isAtEnd() {
                values.append(try Value(from: &value, as: valueType, runtime: runtime))
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodeVariant(
        from: inout ValueDecodingContainer, path: String?, type: RuntimeTypeId,
        variants: [RuntimeTypeVariantItem], runtime: Runtime
    ) throws -> Self {
        guard path != "Option" else { // Option<T> can be null or value
            let someType = variants.first(where: { $0.name == "Some" })!.fields[0].type
            if try from.decodeNil() {
                return Value(value: .variant(.sequence(name: "None", values: [])), context: type)
            }
            let some = try Value(from: &from, as: someType, runtime: runtime)
            return Value(value: .variant(.sequence(name: "Some", values: [some])), context: type)
        }
        if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: runtime.decoder(with: data), as: type, runtime: runtime)
        } else {
            var container = try from.nestedKeyedContainer()
            var variant: RuntimeTypeVariantItem
            if try container.contains(key: "name") {
                try container.next(key: "name")
                let name = try container.decode(String.self)
                guard let found = variants.first(where: { $0.name == name }) else {
                    throw try container.newError("Found unknown variant: \(name)")
                }
                try container.next(key: "values")
                variant = found
            } else if try container.contains(key: "type") {
                try container.next(key: "type")
                let name = try container.decode(String.self)
                guard let found = variants.first(where: { $0.name == name }) else {
                    throw try container.newError("Found unknown variant: \(name)")
                }
                container = from
                variant = found
            } else {
                guard let found = try variants.first(where: { try container.contains(key: $0.name) }) else {
                    throw try container.newError("variant not found")
                }
                try container.next(key: found.name.camelCased(with: "_"))
                variant = found
            }
            let value = try Self._decodeComposite(from: &container, type: type,
                                                  fields: variant.fields, runtime: runtime)
            switch value.value {
            case .map(let map):
                return Value(value: .variant(.map(name: variant.name, fields: map)), context: type)
            case .sequence(let fields):
                return Value(value: .variant(.sequence(name: variant.name, values: fields)), context: type)
            default: fatalError("Should never be called for composite")
            }
        }
    }
    
    static func _decodeArray(
        from: inout ValueDecodingContainer, type: RuntimeTypeId,
        count: UInt32, valueType: RuntimeTypeId, runtime: Runtime
    ) throws -> Self {
        guard let vTypeInfo = runtime.resolve(type: valueType) else {
            throw DecodingError.typeNotFound(valueType)
        }
        if case .primitive(is: .u8) = vTypeInfo.definition { // [u8] array
            if let data = try? from.decode(Data.self) {
                guard data.count == count else {
                    throw try from.newError("Wrong data size: \(data.count), expected: \(count)")
                }
                return Value(value: .primitive(.bytes(data)), context: type)
            } else if let data = try? from.decode([UInt8].self) {
                guard data.count == count else {
                    throw try from.newError("Wrong array size: \(data.count), expected: \(count)")
                }
                return Value(value: .primitive(.bytes(Data(data))), context: type)
            } else {
                throw try from.newError("Expected hex or [u8] for data")
            }
        } else if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: runtime.decoder(with: data), as: type, runtime: runtime)
        } else { // array
            var value = try from.nestedUnkeyedContainer()
            var values = Array<Self>()
            values.reserveCapacity(Int(count))
            while try !value.isAtEnd() {
                values.append(try Value(from: &value, as: valueType, runtime: runtime))
            }
            guard values.count == count else {
                throw try from.newError("Wrong array size: \(values.count), expected: \(count)")
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodeTuple(
        from: inout ValueDecodingContainer, type: RuntimeTypeId, fields: [RuntimeTypeId], runtime: Runtime
    ) throws -> Self {
        // Should we check 1 element tuples as value?
        if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: runtime.decoder(with: data), as: type, runtime: runtime)
        } else {
            var container = try from.nestedUnkeyedContainer()
            let seq = try fields.map { try Value(from: &container, as: $0, runtime: runtime) }
            return Value(value: .sequence(seq), context: type)
        }
    }
    
    static func _decodePrimitive(
        from: inout ValueDecodingContainer, type: RuntimeTypeId, prim: RuntimeTypePrimitive, runtime: Runtime
    ) throws -> Self {
        switch prim {
        case .bool: return Value(value: .primitive(.bool(try from.decode(Bool.self))), context: type)
        case .char:
            let string = try from.decode(String.self)
            guard string.unicodeScalars.count == 1 else {
                throw try from.newError("Bad character string: \(string)")
            }
            return Value(value: .primitive(.char(Character(string.unicodeScalars.first!))), context: type)
        case .str: return Value(value: .primitive(.string(try from.decode(String.self))), context: type)
        case .u8, .u16, .u32, .u64:
            let value = try from.decode(HexOrNumber<UInt64>.self)
            return Value(value: .primitive(.u256(UInt256(value.value))), context: type)
        case .u128, .u256:
            if let value = try? from.decode(UInt64.self) {
                return Value(value: .primitive(.u256(UInt256(value))), context: type)
            } else {
                return Value(value: .primitive(.u256(try from.decode(UIntHex<UInt256>.self).value)),
                             context: type)
            }
        case .i8, .i16, .i32, .i64, .i128, .i256:
            return Value(value: .primitive(.i256(Int256(try from.decode(Int64.self)))),
                         context: type)
        }
    }
    
    static func _decodeCompact(
        from: inout ValueDecodingContainer, type: RuntimeTypeId, of: RuntimeTypeId, runtime: Runtime
    ) throws -> Self {
        var innerTypeId = of
        var value: Self? = nil
        while value == nil {
            guard let innerType = runtime.resolve(type: innerTypeId)?.definition else {
                throw try from.newError("Type not found: \(type)")
            }
            switch innerType {
            case .primitive(is: let prim):
                switch prim {
                case .u8, .u16, .u32, .u64, .u128, .u256:
                    value = try Self._decodePrimitive(from: &from, type: type,
                                                      prim: prim, runtime: runtime)
                default: throw try from.newError("Can't compact decode: \(innerType)")
                }
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    throw try from.newError("Can't compact decode: \(innerType)")
                }
                innerTypeId = fields[0].type
            case .tuple(components: let fields):
                guard fields.count == 1 else {
                    throw try from.newError("Can't compact decode: \(innerType)")
                }
                innerTypeId = fields[0]
            default: throw try from.newError("Can't compact decode: \(innerType)")
            }
        }
        return value!
    }
    
    static func _decodeBitSequence(
        from: inout ValueDecodingContainer, type: RuntimeTypeId,
        store: RuntimeTypeId, order: RuntimeTypeId, runtime: Runtime
    ) throws -> Self {
        if let data = try? from.decode(Data.self) { // SCALE serialized
            return try Value(from: runtime.decoder(with: data), as: type, runtime: runtime)
        }
        let bools = try from.decode([Bool].self)
        return Value(value: .bitSequence(BitSequence(bits: bools, order: .lsb0)),
                     context: type)
    }
}
