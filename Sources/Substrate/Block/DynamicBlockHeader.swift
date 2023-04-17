//
//  DynamicBlockHeader.swift
//  
//
//  Created by Yehor Popovych on 20.03.2023.
//

import Foundation
import ScaleCodec

public struct DynamicBlockHeader: AnyBlockHeader {
    public typealias THasher = DynamicHasher
    public typealias TNumber = UInt256
    
    private var _runtime: any Runtime
    
    public let fields: [String: Value<RuntimeTypeId>]
    public var number: UInt256
    public let type: RuntimeTypeInfo
    
    public var hash: DynamicHash {
        let value = Value<RuntimeTypeId>(value: .map(fields), context: type.id)
        let encoder = _runtime.encoder()
        try! value.encode(in: encoder,
                          as: type.id,
                          runtime: _runtime)
        return try! DynamicHash(_runtime.hasher.hash(data: encoder.output))
    }
    
    public init(from decoder: Decoder) throws {
        self._runtime = decoder.runtime
        var container = ValueDecodingContainer(decoder)
        guard let type = _runtime.blockHeaderType else {
            throw try container.newError("Block header type is nil")
        }
        self.type = type
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
