//
//  AnyBloc.swift
//  
//
//  Created by Yehor Popovych on 20.03.2023.
//

import Foundation
import ScaleCodec

public struct AnyBlock<H: FixedHasher, N: UnsignedInteger & DataConvertible, E: OpaqueExtrinsic>: SomeBlock {
    public enum TypeError: Error {
        case blockNotFound(id: RuntimeType.Id)
        case headerNotFound(inBlock: RuntimeType.Info)
    }
    
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    public typealias THeader = Header
    public typealias TExtrinsic = E
    
    public let header: Header
    public let extrinsics: [E]
    
    public let other: [String: Value<RuntimeType.Id>]?
    public let type: RuntimeType.Info
    
    public init(from decoder: Swift.Decoder, as type: RuntimeType.Id, runtime: Runtime) throws {
        guard let info = Self.fieldTypes(id: type, runtime: runtime) else {
            throw try Swift.DecodingError.dataCorruptedError(
                in: decoder.singleValueContainer(),
                debugDescription: "Type not found: \(type)"
            )
        }
        self.type = info.info
        guard let header = info.header else {
            throw Swift.DecodingError.typeMismatch(
                RuntimeType.Field.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Can't find header in Block: \(info.info)")
            )
        }
        guard let extrinsic = info.extrinsic else {
            throw Swift.DecodingError.typeMismatch(
                RuntimeType.Field.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Can't find extrinsics in Block: \(info.info)")
            )
        }
        let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
        self.header = try container.decode(
            THeader.self, forKey: header.0,
            context: THeader.DecodingContext(runtime: runtime){ _ in header.1 }
        )
        var extrinsics = [TExtrinsic]()
        var eContext = try container.nestedUnkeyedContainer(forKey: extrinsic.0)
        if let count = eContext.count { extrinsics.reserveCapacity(count) }
        while !eContext.isAtEnd {
            try extrinsics.append(
                eContext.decode(E.self,
                                context: E.DecodingContext(runtime: runtime){_ in extrinsic.1}))
        }
        self.extrinsics = extrinsics
        self.other = try info.other.map { other in
            try other.map { (key, type) in
                let val = try container.decode(
                    Value<RuntimeType.Id>.self, forKey: key,
                    context: .init(runtime: runtime) { _ in type}
                )
                return (key.stringValue, val)
            }
        }.flatMap { Dictionary(uniqueKeysWithValues: $0) }
    }
    
    public static func headerType(runtime: Runtime,
                                  block id: RuntimeType.Id) throws -> RuntimeType.Id
    {
        guard let info = Self.fieldTypes(id: id, runtime: runtime) else {
            throw TypeError.blockNotFound(id: id)
        }
        guard let header = info.header else {
            throw TypeError.headerNotFound(inBlock: info.info)
        }
        return header.1
    }
    
    private static func fieldTypes(
        id: RuntimeType.Id, runtime: any Runtime
    ) -> (info: RuntimeType.Info, header: (AnyCodableCodingKey, RuntimeType.Id)?,
          extrinsic: (AnyCodableCodingKey, RuntimeType.Id)?,
          other: [AnyCodableCodingKey: RuntimeType.Id]?)?
    {
        guard let type = runtime.resolve(type: id) else {
            return nil
        }
        let info = RuntimeType.Info(id: id, type: type)
        switch type.definition {
        case .composite(fields: let fields):
            guard fields.count >= 2 else {
                return (info: info, header: nil, extrinsic: nil, other: nil)
            }
            let header: (AnyCodableCodingKey, RuntimeType.Id)
            let extrinsics: (AnyCodableCodingKey, RuntimeType.Id)
            let filtered: [RuntimeType.Field]
            if fields[0].name != nil { // Named
                guard let hField = fields.first(where: { $0.name!.lowercased() == Self.headerKey }) else {
                    return (info: info, header: nil, extrinsic: nil, other: nil)
                }
                header = (AnyCodableCodingKey(Self.headerKey), hField.type)
                guard let eField = fields.first(where: { $0.name!.lowercased() == Self.extrinsicsKey }) else {
                    return (info: info, header: header, extrinsic: nil, other: nil)
                }
                extrinsics = (AnyCodableCodingKey(Self.extrinsicsKey), eField.type)
                filtered = fields.filter { ![Self.headerKey, Self.extrinsicsKey].contains($0.name!.lowercased()) }
            } else { // Unnamed
                header = (AnyCodableCodingKey(0), fields[0].type)
                extrinsics = (AnyCodableCodingKey(1), fields[1].type)
                filtered = fields.count > 2 ? Array(fields.suffix(from: 2)) : []
            }
            guard let extrinsicsType = runtime.resolve(type: extrinsics.1) else {
                return (info: info, header: header, extrinsic: nil, other: nil)
            }
            guard case .sequence(of: let extrinsicId) = extrinsicsType.definition else {
                return (info: info, header: header, extrinsic: nil, other: nil)
            }
            if filtered.count == 0 {
                return (info: info, header: header,
                        extrinsic: (extrinsics.0, extrinsicId), other: nil)
            }
            let other = filtered.enumerated().map {
                let key = $0.element.name.map { AnyCodableCodingKey($0) }
                    ?? AnyCodableCodingKey($0.offset + 2)
                return (key, $0.element.type)
            }
            return (info: info, header: header, extrinsic: (extrinsics.0, extrinsicId),
                    other: Dictionary(uniqueKeysWithValues: other))
        default: return (info: info, header: nil, extrinsic: nil, other: nil)
        }
    }
    
    @inlinable public static var headerKey: String { "header" }
    @inlinable public static var extrinsicsKey: String { "extrinsics" }
}

public extension AnyBlock {
    struct Header: SomeBlockHeader, RuntimeDynamicSwiftDecodable {
        public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
        public typealias THasher = H
        public typealias TNumber = N
        
        private var _runtime: any Runtime
        
        public let fields: [String: Value<RuntimeType.Id>]
        public let number: TNumber
        public let type: RuntimeType.Id
        
        public var hash: THasher.THash {
            let value = Value<RuntimeType.Id>(value: .map(fields), context: type)
            let data = try! _runtime.encode(value: value, as: type)
            return try! THasher.THash(_runtime.hasher.hash(data: data))
        }
        
        public init(from decoder: Swift.Decoder, `as` type: RuntimeType.Id, runtime: any Runtime) throws {
            self._runtime = runtime
            self.type = type
            var container = ValueDecodingContainer(decoder)
            let value = try Value<RuntimeType.Id>(from: &container, as: type, runtime: _runtime, custom: true)
            guard let map = value.map else {
                throw try container.newError("Header is not a map: \(value)")
            }
            self.fields = map
            guard let number = fields["number"]?.u256 else {
                throw try container.newError("Header doesn't have number: \(value)")
            }
            guard let converted = TNumber(exactly: number) else {
                throw try container.newError("Header number \(value) can't be stored in: \(TNumber.self)")
            }
            self.number = converted
        }
    }
}
