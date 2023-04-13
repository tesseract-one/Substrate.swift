//
//  Block.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec
import Serializable

public protocol AnyBlock: Decodable {
    associatedtype THeader: AnyBlockHeader
    associatedtype TExtrinsic: OpaqueExtrinsic
    
    var hash: THeader.THasher.THash { get }
    var header: THeader { get }
    var extrinsics: [TExtrinsic] { get }
}

extension AnyBlock {
    public func dynamicExtrinsics() throws -> [Extrinsic<DynamicCall<RuntimeTypeId>, Value<RuntimeTypeId>>] {
        try extrinsics.map { try $0.decode() }
    }
}

public extension AnyBlock {
    var hash: THeader.THasher.THash { header.hash }
}

public protocol AnyBlockHeader: Decodable {
    associatedtype TNumber: UnsignedInteger & DataConvertible
    associatedtype THasher: FixedHasher
    
    var number: TNumber { get }
    var hash: THasher.THash { get }
}

public protocol AnyChainBlock<TBlock>: Decodable {
    associatedtype TBlock: AnyBlock
    
    var block: TBlock { get }
}

public struct Block<H: AnyBlockHeader, E: OpaqueExtrinsic>: AnyBlock {
    public let header: H
    public let extrinsics: [E]
}

public struct ChainBlock<B: AnyBlock>: AnyChainBlock {
    public let block: B
    public let justifications: SerializableValue
}
