//
//  AnyBlockHeader.swift
//  
//
//  Created by Yehor Popovych on 20.03.2023.
//

import Foundation
import ScaleCodec

public struct AnyBlockHeader<THasher: FixedHasher>: SomeBlockHeader {
    public typealias THasher = THasher
    public typealias TNumber = UInt256
    
    private var _runtime: any Runtime
    
    public let fields: [String: Value<RuntimeTypeId>]
    public let number: UInt256
    public let type: RuntimeTypeInfo
    
    public var hash: THasher.THash {
        let value = Value<RuntimeTypeId>(value: .map(fields), context: type.id)
        let data = try! _runtime.encode(value: value, as: type.id)
        return try! THasher.THash(_runtime.hasher.hash(data: data))
    }
    
    public init(from decoder: Swift.Decoder) throws {
        self._runtime = decoder.runtime
        let type = try _runtime.types.blockHeader
        self.type = type
        var container = ValueDecodingContainer(decoder)
        let value = try Value<RuntimeTypeId>(from: &container, as: type.id, runtime: _runtime)
        guard let map = value.map else {
            throw try container.newError("Header is not a map: \(value)")
        }
        self.fields = map
        guard let number = fields["number"]?.u256 else {
            throw try container.newError("Header doesn't have number: \(value)")
        }
        self.number = number
    }
}
