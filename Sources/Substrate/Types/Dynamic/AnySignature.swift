//
//  AnySignature.swift
//  
//
//  Created by Yehor Popovych on 14/07/2023.
//

import Foundation
import ScaleCodec

public struct AnySignature: Signature {
    public enum Error: Swift.Error {
        case unsupportedCrypto(id: CryptoTypeId)
        case unsupportedCrypto(name: String)
        case variantIsNotBytes(Value<RuntimeType.Id>.Variant)
        case rawBytesForMultiSignature(value: Value<RuntimeType.Id>)
        case wrongValueType(value: Value<RuntimeType.Id>)
    }
    private let _sig: MultiSignature
    
    public var raw: Data { _sig.raw }
    public var algorithm: CryptoTypeId { _sig.algorithm }
    
    public init(raw: Data, algorithm: CryptoTypeId, runtime: Runtime, id: RuntimeType.LazyId) throws {
        let algos = try Self.algorithms(runtime: runtime, id: id)
        guard algos.contains(algorithm) else {
            throw Error.unsupportedCrypto(id: algorithm)
        }
        _sig = try MultiSignature(raw: raw, algorithm: algorithm, runtime: runtime)
    }
    
    public init<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: RuntimeType.Id, runtime: Runtime
    ) throws {
        let value = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
            .flatten(runtime: runtime)
        switch value.value {
        case .variant(let variant):
            let algos = try Self.parseTypeInfo(runtime: runtime, typeId: type).getValueError()
            guard let algo = algos[variant.name] else {
                throw Error.unsupportedCrypto(name: variant.name)
            }
            guard let bytes = variant.values.first?.bytes else {
                throw Error.variantIsNotBytes(variant)
            }
            _sig = try MultiSignature(raw: bytes, algorithm: algo, runtime: runtime)
        case .primitive(.bytes(let data)):
            let algorithms = try Self.algorithms(runtime: runtime, id: { _ in type})
            guard algorithms.count == 1 else {
                throw Error.rawBytesForMultiSignature(value: value)
            }
            _sig = try MultiSignature(raw: data, algorithm: algorithms[0], runtime: runtime)
        default:
            throw Error.wrongValueType(value: value)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(
        in encoder: inout E, as type: RuntimeType.Id, runtime: Runtime
    ) throws {
        try asValue(runtime: runtime, type: type).encode(in: &encoder, as: type, runtime: runtime)
    }
    
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        let algos = try Self.parseTypeInfo(runtime: runtime, typeId: type).getValueError()
        if algos.count == 1 {
            guard algos.first!.value == _sig.algorithm else {
                throw Error.unsupportedCrypto(id: algos.first!.value)
            }
            return .bytes(_sig.raw, type)
        }
        guard let pair = algos.first(where: { $0.value == _sig.algorithm }) else {
            throw Error.unsupportedCrypto(id: _sig.algorithm)
        }
        return .variant(name: pair.key, values: [.bytes(_sig.raw, type)], type)
    }
    
    public static func algorithms(runtime: Runtime,
                                  id: RuntimeType.LazyId) throws -> [CryptoTypeId]
    {
        try Array(parseTypeInfo(runtime: runtime, typeId: id(runtime)).getValueError().values)
    }
    
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        parseTypeInfo(runtime: runtime, typeId: id).map{_ in}
    }
    
    public static func parseTypeInfo(
        runtime: Runtime, typeId: RuntimeType.Id
    ) -> Result<[String: CryptoTypeId], TypeValidationError> {
        guard let type = runtime.resolve(type: typeId) else {
            return .failure(.typeNotFound(typeId))
        }
        switch type.definition {
        case .variant(variants: let variants):
            let mapped: Result<[(String, CryptoTypeId)], TypeValidationError> = variants.resultMap { item in
                if let id = CryptoTypeId.byName[item.name.lowercased()] {
                    return .success((item.name, id))
                }
                guard item.fields.count == 1 else {
                    return .failure(.wrongValuesCount(in: type, expected: 1,
                                                      for: "Signature"))
                }
                if let typeName = item.fields[0].typeName?.lowercased() {
                    if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                        return .success((item.name, CryptoTypeId.byName[name]!))
                    }
                }
                guard let type = runtime.resolve(type: item.fields[0].type) else {
                    return .failure(.typeNotFound(item.fields[0].type))
                }
                if let typeName = type.name?.lowercased() {
                    if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                        return .success((item.name, CryptoTypeId.byName[name]!))
                    }
                }
                return .failure(.wrongType(got: type, for: "Signature"))
            }
            return mapped.map{Dictionary(uniqueKeysWithValues: $0)}
        case .composite(fields: let fields):
            if let typeName = type.name?.lowercased() {
                if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                    return .success(["": CryptoTypeId.byName[name]!])
                }
            }
            guard fields.count == 1 else {
                return .failure(.wrongValuesCount(in: type, expected: 1,
                                                  for: "Signature"))
            }
            if let typeName = fields[0].typeName?.lowercased() {
                if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                    return .success(["": CryptoTypeId.byName[name]!])
                }
            }
            return parseTypeInfo(runtime: runtime, typeId: fields[0].type)
        case .tuple(components: let ids):
            if let typeName = type.name?.lowercased() {
                if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                    return .success(["": CryptoTypeId.byName[name]!])
                }
            }
            guard ids.count == 1 else {
                return .failure(.wrongValuesCount(in: type, expected: 1,
                                                  for: "Signature"))
            }
            return parseTypeInfo(runtime: runtime, typeId: ids[0])
        default:
            return .failure(.wrongType(got: type, for: "Signature"))
        }
    }
}
