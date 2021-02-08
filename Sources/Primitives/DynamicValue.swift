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
}
