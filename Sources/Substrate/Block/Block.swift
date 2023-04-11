//
//  Block.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec
import Serializable

public protocol Block: Decodable {
    associatedtype THeader: BlockHeader
    associatedtype TExtrinsic: OpaqueExtrinsic
    
    var hash: THeader.THasher.THash { get }
    var header: THeader { get }
    var extrinsics: [TExtrinsic] { get }
}

public extension Block {
    var hash: THeader.THasher.THash { header.hash }
}

public protocol BlockHeader: Decodable {
    associatedtype TNumber: UnsignedInteger & DataConvertible
    associatedtype THasher: FixedHasher
    
    var number: TNumber { get }
    var hash: THasher.THash { get }
}

public protocol AnyChainBlock<TBlock>: Decodable {
    associatedtype TBlock: Block
    
    var block: TBlock { get }
}

public struct ChainBlock<B: Block>: Decodable, AnyChainBlock {
    public let block: B
    public let justifications: SerializableValue
}
