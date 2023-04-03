//
//  DynamicBlock.swift
//  
//
//  Created by Yehor Popovych on 20.03.2023.
//

import Foundation
import ScaleCodec

public struct DynamicBlockHeader<HS: NormalHasher>: Decodable, BlockHeader {
    public typealias THasher = HS
    public typealias TNumber = UInt256
    
    private var _registry: any Registry
    
    public let fields: [String: Value<RuntimeTypeId>]
    public var number: ScaleCodec.UInt256
    
    public var hash: HS.THash
    
    public init(from decoder: Decoder) throws {
        self._registry = decoder.registry
        let value = Value<RuntimeTypeId>(from: <#T##ScaleDecoder#>, as: <#T##RuntimeTypeId#>, registry: <#T##Registry#>)
    }
}

public struct SubstrateBlock<HS: NormalHasher, BN: UnsignedInteger & DataConvertible, E: OpaqueExtrinsic> {
    public let header: DynamicBlockHeader<HS, BN>
    public let extrinsics: [E]
}
