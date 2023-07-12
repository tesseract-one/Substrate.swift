//
//  Either.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation
import ContextCodable

public enum Either<Left, Right>: CustomStringConvertible {
    case left(Left)
    case right(Right)
    
    public var isLeft: Bool {
        switch self {
        case .left(_): return true
        case .right(_): return false
        }
    }
    
    public var isRight: Bool {
        switch self {
        case .left(_): return false
        case .right(_): return true
        }
    }
    
    public var left: Left? {
        switch self {
        case .left(let l): return l
        case .right(_): return nil
        }
    }
    
    public var right: Right? {
        switch self {
        case .left(_): return nil
        case .right(let r): return r
        }
    }
    
    public var ok: Right? { right }
    public var err: Left? { left }
    
    public var description: String {
        switch self {
        case .left(let l): return "\(l)"
        case .right(let r): return "\(r)"
        }
    }
    
    public init(ok right: Right) {
        self = .right(right)
    }
    
    public init(err left: Left) {
        self = .left(left)
    }
}

extension Either: Equatable where Left: Equatable, Right: Equatable {}
extension Either: Hashable where Left: Hashable, Right: Hashable {}
extension Either: Error where Left: Error, Right: Error {}

extension Either: ContextDecodable where Left: ContextDecodable, Right: ContextDecodable {
    public typealias DecodingContext = (keys: (left: String, right: String)?,
                                        contexts: (left: Left.DecodingContext, right: Right.DecodingContext))
    
    public init(from decoder: Decoder, context: DecodingContext) throws {
        if let keys = context.keys {
            var container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
            if container.contains(AnyCodableCodingKey(keys.left)) {
                self = try .left(container.decode(Left.self,
                                                  forKey: AnyCodableCodingKey(keys.left),
                                                  context: context.contexts.left))
            } else if container.contains(AnyCodableCodingKey(keys.right)) {
                self = try .right(container.decode(Right.self,
                                                   forKey: AnyCodableCodingKey(keys.right),
                                                   context: context.contexts.right))
            } else {
                throw DecodingError.keyNotFound(
                    AnyCodableCodingKey(keys.left),
                    .init(codingPath: container.codingPath,
                          debugDescription: "None of the keys found for Either")
                )
            }
        } else {
            if let left = try? Left(from: decoder, context: context.contexts.left) {
                self = .left(left)
            } else {
                self = try .right(Right(from: decoder, context: context.contexts.right))
            }
        }
    }
}
