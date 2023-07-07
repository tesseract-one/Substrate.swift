//
//  AnyBloc.swift
//  
//
//  Created by Yehor Popovych on 20.03.2023.
//

import Foundation
import ScaleCodec

public struct AnyBlockHeader<THasher: FixedHasher, TNumber: UnsignedInteger & DataConvertible>: SomeBlockHeader {
    public typealias THasher = THasher
    public typealias TNumber = TNumber
    
    private var _runtime: any Runtime
    
    public let fields: [String: Value<RuntimeTypeId>]
    public let number: TNumber
    public let type: RuntimeTypeId
    
    public var hash: THasher.THash {
        let value = Value<RuntimeTypeId>(value: .map(fields), context: type)
        let data = try! _runtime.encode(value: value, as: type)
        return try! THasher.THash(_runtime.hasher.hash(data: data))
    }
    
    public init(from decoder: Swift.Decoder, `as` type: RuntimeTypeId, runtime: any Runtime) throws {
        self._runtime = runtime
        self.type = type
        var container = ValueDecodingContainer(decoder)
        let value = try Value<RuntimeTypeId>(from: &container, as: type, runtime: _runtime)
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

public struct AnyBlock<H: SomeBlockHeader, E: OpaqueExtrinsic>: SomeBlock {
    public let header: H
    public let extrinsics: [E]
    
    public let fields: [String: Value<RuntimeTypeId>]
    public let type: RuntimeTypeInfo
    
    public init(from decoder: Swift.Decoder, as type: RuntimeTypeId, runtime: Runtime) throws {
        guard let info = runtime.resolve(type: type) else {
            throw try Swift.DecodingError.dataCorruptedError(
                in: decoder.singleValueContainer(),
                debugDescription: "Type not found: \(type)"
            )
        }
        self.type = RuntimeTypeInfo(id: type, type: info)
        switch info.definition {
        case .composite(fields: let fields):
            fatalError()
        case .tuple(components: let ids):
            guard ids.count >= 2 else {
                throw try Swift.DecodingError.dataCorruptedError(
                    in: decoder.singleValueContainer(),
                    debugDescription: "Less than 2 elements tuple"
                )
            }
            var container = try decoder.unkeyedContainer()
            header = try container.decode(H.self, context: (runtime, {_ in ids[0]}))
            extrinsics = try container.decode([E].self, context: runtime)
            var fields = Dictionary<String, Value<RuntimeTypeId>>()
            if ids.count > 2 {
                fields.reserveCapacity(ids.count - 2)
                for (index, id) in ids.suffix(from: 2).enumerated() {
                    fields[String(index)] = try container.decode(Value<RuntimeTypeId>.self,
                                                                 context: (runtime, { _ in id }))
                }
            }
        default:
            fatalError()
        }
    }
}
