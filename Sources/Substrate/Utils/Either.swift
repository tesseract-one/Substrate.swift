//
//  Either.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation

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
    
    public var description: String {
        switch self {
        case .left(let l): return "\(l)"
        case .right(let r): return "\(r)"
        }
    }
}

extension Either: Equatable where Left: Equatable, Right: Equatable {}
extension Either: Hashable where Left: Hashable, Right: Hashable {}
