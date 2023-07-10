//
//  Block.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec
import ContextCodable

public protocol SomeBlock: RuntimeDynamicSwiftDecodable {
    associatedtype THeader: SomeBlockHeader
    associatedtype TExtrinsic: OpaqueExtrinsic
    
    var hash: THeader.THasher.THash { get }
    var header: THeader { get }
    var extrinsics: [TExtrinsic] { get }
    
    static func headerType(runtime: any Runtime,
                           block id: RuntimeType.Id) throws -> RuntimeType.Id
}

public extension SomeBlock {
    var hash: THeader.THasher.THash { header.hash }
}

public protocol SomeBlockHeader: RuntimeDynamicSwiftDecodable {
    associatedtype TNumber: UnsignedInteger & DataConvertible
    associatedtype THasher: FixedHasher
    
    var number: TNumber { get }
    var hash: THasher.THash { get }
}

public protocol StaticBlock: SomeBlock, RuntimeSwiftDecodable where THeader: RuntimeSwiftDecodable {}

public extension StaticBlock {
    // Should never be called because of the static Header parsing
    static func headerType(runtime: any Runtime,
                           block id: @escaping RuntimeType.LazyId) throws -> RuntimeType.Id {
        try RuntimeType.IdNever(runtime)
    }
}

public protocol SomeChainBlock<TBlock>: ContextDecodable where
    DecodingContext == (runtime: Runtime, blockType: RuntimeType.LazyId)
{
    associatedtype TBlock: SomeBlock
    
    var block: TBlock { get }
}

public protocol StaticChainBlock: SomeChainBlock where TBlock: StaticBlock {
    init(from decoder: Swift.Decoder, runtime: any Runtime) throws
}

public extension StaticChainBlock {
    init(from decoder: Swift.Decoder,
         context: (runtime: Runtime, blockType: RuntimeType.LazyId)) throws {
        try self.init(from: decoder, runtime: context.runtime)
    }
}

public struct AnyChainBlock<B: SomeBlock, J: Swift.Decodable>: SomeChainBlock {
    public let block: B
    public let justifications: J
    
    enum CodingKeys: CodingKey {
        case block
        case justifications
    }
    
    public init(from decoder: Swift.Decoder,
                context: (runtime: Runtime, blockType: RuntimeType.LazyId)) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        block = try container.decode(
            B.self, forKey: .block,
            context: B.DecodingContext(runtime: context.runtime,
                                       type: context.blockType)
        )
        justifications = try container.decode(J.self, forKey: .justifications)
    }
}

public extension Array where Element: OpaqueExtrinsic {
    func parsed() throws -> [AnyExtrinsic<AnyCall<RuntimeType.Id>, Element.TManager>] {
        try map { try $0.decode() }
    }
}
