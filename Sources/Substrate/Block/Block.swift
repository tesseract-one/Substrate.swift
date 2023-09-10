//
//  Block.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec
import ContextCodable

public protocol SomeBlock: RuntimeDynamicSwiftDecodable, ValidatableType {
    associatedtype THeader: SomeBlockHeader
    associatedtype TExtrinsic: OpaqueExtrinsic
    
    var hash: THeader.THasher.THash { get }
    var header: THeader { get }
    var extrinsics: [TExtrinsic] { get }
    
    static func headerType(block type: TypeDefinition) throws -> TypeDefinition
}

public extension SomeBlock {
    var hash: THeader.THasher.THash { header.hash }
}

public protocol SomeBlockHeader: RuntimeDynamicSwiftDecodable, ValidatableType {
    associatedtype TNumber: UnsignedInteger & DataConvertible
    associatedtype THasher: FixedHasher
    
    var number: TNumber { get }
    var hash: THasher.THash { get }
}

public protocol StaticBlock: SomeBlock, RuntimeSwiftDecodable where THeader: RuntimeSwiftDecodable {}

public protocol SomeChainBlock<TBlock>: ContextDecodable where
    DecodingContext == (runtime: Runtime, blockType: TypeDefinition.Lazy)
{
    associatedtype TBlock: SomeBlock
    
    var block: TBlock { get }
}

public protocol StaticChainBlock: SomeChainBlock where TBlock: StaticBlock {
    init(from decoder: Swift.Decoder, runtime: any Runtime) throws
}

public extension StaticChainBlock {
    init(from decoder: Swift.Decoder,
         context: (runtime: Runtime, blockType: TypeDefinition.Lazy)) throws {
        try self.init(from: decoder, runtime: context.runtime)
    }
}

public extension SomeBlock {
    static func headerType(block type: TypeDefinition) throws -> TypeDefinition
    {
        guard case .composite(let fields) = type.flatten().definition else {
            throw TypeError.wrongType(for: Self.self, type: type,
                                      reason: "Isn't Composite", .get())
        }
        guard let header = fields.first(where: {$0.name == "header"}) else {
            throw TypeError.fieldNotFound(for: Self.self, field: "header",
                                          type: type, .get())
        }
        return header.type
    }
}
