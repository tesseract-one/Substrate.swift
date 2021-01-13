//
//  DynamicValue.swift
//  
//
//  Created by Yehor Popovych on 1/6/21.
//

import Foundation

public indirect enum DValue: Error {
    case null
    case native(type: DType, value: ScaleDynamicDecodable)
    case collection(values: [DValue])
    case map(values: [(key: DValue, value: DValue)])
    case result(res: Result<DValue, DValue>)
}

extension DValue {
    public init(_ value: ScaleDynamicDecodable) {
        let name = String(describing: type(of: value))
        self = .native(type: .type(name: name), value: value)
    }
}
