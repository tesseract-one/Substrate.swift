//
//  DynamicValue.swift
//  
//
//  Created by Yehor Popovych on 1/6/21.
//

import Foundation
import ScaleCodec

public indirect enum DValue: Error {
    case null
    case native(type: DType, value: ScaleDynamicCodable)
    case collection(values: [DValue])
    case map(values: [(key: DValue, value: DValue)])
    case result(res: Result<DValue, DValue>)
    
    public init<T: ScaleDynamicCodable>(native: T, registry: TypeRegistryProtocol) throws {
        self = try registry.value(dynamic: native)
    }
}


public protocol ScaleDynamicEncodableArrayMaybeConvertible {
    var encodableArray: Array<ScaleDynamicEncodable>? { get }
}
