//
//  AnyChainBlock.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import Serializable

public struct AnyChainBlock<B: SomeBlock>: SomeChainBlock {
    public let block: B
    public let other: [String: SerializableValue]
    
    public init(from decoder: Decoder,
                context: (runtime: Runtime, blockType: RuntimeType.LazyId)) throws {
        let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
        var block: B? = nil
        var other: [String: SerializableValue] = [:]
        for key in container.allKeys {
            if key.stringValue == "block" {
                block = try container.decode(
                    B.self, forKey: key,
                    context: B.DecodingContext(runtime: context.runtime,
                                               type: context.blockType)
                )
            } else {
                other[key.stringValue] = try container.decode(SerializableValue.self, forKey: key)
            }
        }
        guard let block = block else {
            throw DecodingError.keyNotFound(
                AnyCodableCodingKey("block"),
                .init(codingPath: container.codingPath,
                      debugDescription: "'block' key not found in the ChainBlock"))
        }
        self.block = block
        self.other = other
    }
}
