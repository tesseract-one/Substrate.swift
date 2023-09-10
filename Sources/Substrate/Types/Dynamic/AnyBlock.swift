//
//  AnyBloc.swift
//  
//
//  Created by Yehor Popovych on 20.03.2023.
//

import Foundation
import ScaleCodec

public struct AnyBlock<H: FixedHasher,
                       N: UnsignedInteger & CompactCodable & DataConvertible,
                       E: OpaqueExtrinsic>: SomeBlock
{
    public typealias DecodingContext = RuntimeDynamicSwiftCodableContext
    public typealias THeader = Header
    public typealias TExtrinsic = E
    
    public let header: Header
    public let extrinsics: [E]
    
    public let other: [String: Value<TypeDefinition>]?
    public let type: TypeDefinition
    
    public init(from decoder: Swift.Decoder, as type: TypeDefinition, runtime: Runtime) throws {
        let fields = Self.fieldTypes(type: type)
        self.type = type
        guard let header = fields.header else {
            throw Swift.DecodingError.typeMismatch(
                NetworkType.Field.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Can't find header in Block: \(type)")
            )
        }
        guard let extrinsic = fields.extrinsic else {
            throw Swift.DecodingError.typeMismatch(
                NetworkType.Field.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Can't find extrinsics in Block: \(type)")
            )
        }
        let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
        self.header = try container.decode(
            THeader.self, forKey: header.0,
            context: THeader.DecodingContext(runtime: runtime){ header.1 }
        )
        var extrinsics = [TExtrinsic]()
        var eContext = try container.nestedUnkeyedContainer(forKey: extrinsic.0)
        if let count = eContext.count { extrinsics.reserveCapacity(count) }
        while !eContext.isAtEnd {
            try extrinsics.append(
                eContext.decode(E.self,
                                context: E.DecodingContext(runtime: runtime){ extrinsic.1 }))
        }
        self.extrinsics = extrinsics
        self.other = try fields.other.map { other in
            try other.map { (key, type) in
                let val = try container.decode(
                    Value<TypeDefinition>.self, forKey: key,
                    context: .init(runtime: runtime) { type }
                )
                return (key.stringValue, val)
            }
        }.flatMap { Dictionary(uniqueKeysWithValues: $0) }
    }
    
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        let fields = Self.fieldTypes(type: type)
        guard let header = fields.header else {
            return .failure(.fieldNotFound(for: Self.self, field: "header",
                                           type: type, .get()))
        }
        guard let extrinsic = fields.extrinsic else {
            return .failure(.fieldNotFound(for: Self.self, field: "extrinsic",
                                           type: type, .get()))
        }
        return Header.validate(as: header.1, in: runtime).flatMap { _ in
            E.validate(as: extrinsic.1, in: runtime)
        }
    }
    
    private static func fieldTypes(
        type: TypeDefinition
    ) -> (header: (AnyCodableCodingKey, TypeDefinition)?,
          extrinsic: (AnyCodableCodingKey, TypeDefinition)?,
          other: [AnyCodableCodingKey: TypeDefinition]?)
    {
        switch type.definition {
        case .composite(fields: let fields):
            guard fields.count >= 2 else {
                return (header: nil, extrinsic: nil, other: nil)
            }
            let header: (AnyCodableCodingKey, TypeDefinition)
            let extrinsics: (AnyCodableCodingKey, TypeDefinition)
            let filtered: [TypeDefinition.Field]
            if fields[0].name != nil { // Named
                guard let hField = fields.first(where: { $0.name!.lowercased() == Self.headerKey }) else {
                    return (header: nil, extrinsic: nil, other: nil)
                }
                header = (AnyCodableCodingKey(Self.headerKey), *hField.type)
                guard let eField = fields.first(where: { $0.name!.lowercased() == Self.extrinsicsKey }) else {
                    return (header: header, extrinsic: nil, other: nil)
                }
                extrinsics = (AnyCodableCodingKey(Self.extrinsicsKey), *eField.type)
                filtered = fields.filter { ![Self.headerKey, Self.extrinsicsKey].contains($0.name!.lowercased()) }
            } else { // Unnamed
                header = (AnyCodableCodingKey(0), *fields[0].type)
                extrinsics = (AnyCodableCodingKey(1), *fields[1].type)
                filtered = fields.count > 2 ? Array(fields.suffix(from: 2)) : []
            }
            guard case .sequence(of: let extrinsic) = extrinsics.1.definition else {
                return (header: header, extrinsic: nil, other: nil)
            }
            if filtered.count == 0 {
                return (header: header,
                        extrinsic: (extrinsics.0, *extrinsic), other: nil)
            }
            let other = filtered.enumerated().map {
                let key = $0.element.name.map { AnyCodableCodingKey($0) }
                    ?? AnyCodableCodingKey($0.offset + 2)
                return (key, *$0.element.type)
            }
            return (header: header, extrinsic: (extrinsics.0, *extrinsic),
                    other: Dictionary(uniqueKeysWithValues: other))
        default: return (header: nil, extrinsic: nil, other: nil)
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
        
        public let fields: [String: Value<TypeDefinition>]
        public let number: TNumber
        public let type: TypeDefinition
        
        public var hash: THasher.THash {
            let value = Value<TypeDefinition>(value: .map(fields), context: type)
            let data = try! _runtime.encode(value: value)
            return try! _runtime.hash(type: THasher.THash.self, data: data)
        }
        
        public init(from decoder: Swift.Decoder, `as` type: TypeDefinition, runtime: any Runtime) throws {
            self._runtime = runtime
            self.type = type
            var container = ValueDecodingContainer(decoder)
            let value = try Value<TypeDefinition>(from: &container, as: type, runtime: _runtime, custom: true)
            guard let map = value.map else {
                throw try container.newError("Header is not a map: \(value)")
            }
            self.fields = map
            guard let number = fields["number"]?.uint else {
                throw try container.newError("Header doesn't have number: \(value)")
            }
            guard let converted = TNumber(exactly: number) else {
                throw try container.newError("Header number \(value) can't be stored in: \(TNumber.self)")
            }
            self.number = converted
        }
        
        public static func validate(as type: TypeDefinition, in runtime: any Runtime) -> Result<Void, TypeError>
        {
            guard case .composite(fields: let fields) = type.flatten().definition else {
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "Isn't composite", .get()))
            }
            guard let n = fields.first(where: {$0.name == "number"}) else {
                return .failure(.fieldNotFound(for: Self.self, field: "number",
                                               type: type, .get()))
            }
            return Compact<N>.validate(as: *n.type, in: runtime)
        }
    }
}

public extension Array where Element: OpaqueExtrinsic {
    func parsed() throws -> [Extrinsic<AnyCall<TypeDefinition>, Either<Element.TUnsignedExtra, Element.TSignedExtra>>] {
        try map { try $0.decode() }
    }
}
