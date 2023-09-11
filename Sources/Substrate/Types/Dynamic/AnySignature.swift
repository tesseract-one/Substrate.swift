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
        case variantIsNotBytes(Value<TypeDefinition>.Variant)
        case rawBytesForMultiSignature(value: Value<TypeDefinition>)
        case wrongValueType(value: Value<TypeDefinition>)
    }
    private let _sig: MultiSignature
    
    public var raw: Data { _sig.raw }
    public var algorithm: CryptoTypeId { _sig.algorithm }
    
    public init(raw: Data, algorithm: CryptoTypeId, runtime: Runtime, type: TypeDefinition.Lazy) throws {
        let algos = try Self.algorithms(runtime: runtime, type: type)
        guard algos.contains(algorithm) else {
            throw Error.unsupportedCrypto(id: algorithm)
        }
        _sig = try MultiSignature(raw: raw, algorithm: algorithm, runtime: runtime)
    }
    
    public init<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition, runtime: Runtime
    ) throws {
        let value = try Value<TypeDefinition>(from: &decoder, as: type, runtime: runtime).flatten()
        switch value.value {
        case .variant(let variant):
            let algos = try Self.parseTypeInfo(type: type).get()
            guard let algo = algos[variant.name] else {
                throw Error.unsupportedCrypto(name: variant.name)
            }
            guard let bytes = variant.values.first?.flatten().bytes else {
                throw Error.variantIsNotBytes(variant)
            }
            _sig = try MultiSignature(raw: bytes, algorithm: algo, runtime: runtime)
        case .primitive(.bytes(let data)):
            let algorithms = try Self.algorithms(runtime: runtime, type: { type })
            guard algorithms.count == 1 else {
                throw Error.rawBytesForMultiSignature(value: value)
            }
            _sig = try MultiSignature(raw: data, algorithm: algorithms[0], runtime: runtime)
        default:
            throw Error.wrongValueType(value: value)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(
        in encoder: inout E, as type: TypeDefinition, runtime: Runtime
    ) throws {
        try asValue(of: type, in: runtime).encode(in: &encoder, runtime: runtime)
    }
    
    public func asValue(of type: TypeDefinition,
                        in runtime: any Runtime) throws -> Value<TypeDefinition>
    {
        let algos = try Self.parseTypeInfo(type: type).get()
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
                                  type: TypeDefinition.Lazy) throws -> [CryptoTypeId]
    {
        try Array(parseTypeInfo(type: type()).get().values)
    }
    
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        parseTypeInfo(type: type).map{_ in}
    }
    
    public static func parseTypeInfo(type: TypeDefinition) -> Result<[String: CryptoTypeId], TypeError> {
        switch type.definition {
        case .variant(variants: let variants):
            let mapped: Result<[(String, CryptoTypeId)], TypeError> = variants.resultMap { item in
                if let id = CryptoTypeId.byName[item.name.lowercased()] {
                    return .success((item.name, id))
                }
                guard item.fields.count == 1 else {
                    return .failure(.wrongValuesCount(for: Self.self, expected: 1,
                                                      type: type, .get()))
                }
                if let typeName = item.fields[0].typeName?.lowercased() {
                    if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                        return .success((item.name, CryptoTypeId.byName[name]!))
                    }
                }
                let typeName = item.fields[0].type.name.lowercased()
                if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                    return .success((item.name, CryptoTypeId.byName[name]!))
                }
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "Unknown signature type: \(type)", .get()))
            }
            return mapped.map{Dictionary(uniqueKeysWithValues: $0)}
        case .composite(fields: let fields):
            let typeName = type.name.lowercased()
            if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                return .success(["": CryptoTypeId.byName[name]!])
            }
            guard fields.count == 1 else {
                return .failure(.wrongValuesCount(for: Self.self, expected: 1, type: type, .get()))
            }
            if let typeName = fields[0].typeName?.lowercased() {
                if let name = CryptoTypeId.byName.keys.first(where: { typeName.contains($0) }) {
                    return .success(["": CryptoTypeId.byName[name]!])
                }
            }
            let fieldTypeName = fields[0].type.name.lowercased()
            if let name = CryptoTypeId.byName.keys.first(where: { fieldTypeName.contains($0) }) {
                return .success(["": CryptoTypeId.byName[name]!])
            }
            return parseTypeInfo(type: *fields[0].type)
        default:
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Can't be parsed as signature", .get()))
        }
    }
}
