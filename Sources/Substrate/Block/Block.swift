//
//  Block.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec
import Serializable

public protocol SomeBlock: Decodable {
    associatedtype THeader: SomeBlockHeader
    associatedtype TExtrinsic: OpaqueExtrinsic
    
    var hash: THeader.THasher.THash { get }
    var header: THeader { get }
    var extrinsics: [TExtrinsic] { get }
}

public extension SomeBlock {
    var hash: THeader.THasher.THash { header.hash }
    
    func anyExtrinsics() throws -> [AnyExtrinsic<AnyCall<RuntimeTypeId>, TExtrinsic.TManager>] {
        try extrinsics.map { try $0.decode() }
    }
}

public protocol SomeBlockHeader: Decodable {
    associatedtype TNumber: UnsignedInteger & DataConvertible
    associatedtype THasher: FixedHasher
    
    var number: TNumber { get }
    var hash: THasher.THash { get }
}

// Simple marker for static implementations
public protocol StaticBlockHeader: SomeBlockHeader {}

public protocol SomeChainBlock<TBlock>: Decodable {
    associatedtype TBlock: SomeBlock
    
    var block: TBlock { get }
}

public struct Block<H: SomeBlockHeader, E: OpaqueExtrinsic>: SomeBlock {
    public let header: H
    public let extrinsics: [E]
}

public struct ChainBlock<B: SomeBlock, J: Decodable>: SomeChainBlock {
    public let block: B
    public let justifications: J
}
