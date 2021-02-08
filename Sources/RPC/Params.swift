//
//  Params.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation

public struct RpcCallParam: Encodable {
    public let value: Encodable
    
    public init(_ value: Encodable) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

public func RpcCallParams() -> [RpcCallParam] { [] }

public func RpcCallParams(_ p1: Encodable) -> [RpcCallParam] {
    [RpcCallParam(p1)]
}

public func RpcCallParams(_ p1: Encodable, _ p2: Encodable) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2)]
}

public func RpcCallParams(_ p1: Encodable, _ p2: Encodable, _ p3: Encodable) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3)]
}

public func RpcCallParams(_ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4)]
}

public func RpcCallParams(
    _ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable, _ p5: Encodable
) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4), RpcCallParam(p5)]
}

public func RpcCallParams(
    _ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable, _ p5: Encodable,
    _ p6: Encodable
) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4), RpcCallParam(p5),
     RpcCallParam(p6)]
}

public func RpcCallParams(
    _ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable, _ p5: Encodable,
    _ p6: Encodable, _ p7: Encodable
) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4), RpcCallParam(p5),
     RpcCallParam(p6), RpcCallParam(p7)]
}

public func RpcCallParams(
    _ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable, _ p5: Encodable,
    _ p6: Encodable, _ p7: Encodable, _ p8: Encodable
) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4), RpcCallParam(p5),
     RpcCallParam(p6), RpcCallParam(p7), RpcCallParam(p8)]
}

public func RpcCallParams(
    _ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable, _ p5: Encodable,
    _ p6: Encodable, _ p7: Encodable, _ p8: Encodable, _ p9: Encodable
) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4), RpcCallParam(p5),
     RpcCallParam(p6), RpcCallParam(p7), RpcCallParam(p8), RpcCallParam(p9)]
}

public func RpcCallParams(
    _ p1: Encodable, _ p2: Encodable, _ p3: Encodable, _ p4: Encodable, _ p5: Encodable,
    _ p6: Encodable, _ p7: Encodable, _ p8: Encodable, _ p9: Encodable, _ p10: Encodable
) -> [RpcCallParam] {
    [RpcCallParam(p1), RpcCallParam(p2), RpcCallParam(p3), RpcCallParam(p4), RpcCallParam(p5),
     RpcCallParam(p6), RpcCallParam(p7), RpcCallParam(p8), RpcCallParam(p9), RpcCallParam(p10)]
}
