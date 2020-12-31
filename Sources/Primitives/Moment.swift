//
//  Moment.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public struct Moment: ScaleCodable {
    let value: UInt64
    
    init(_ timestamp: UInt64) {
        value = timestamp
    }
    
    init(_ interval: TimeInterval) {
        value = UInt64(interval * 1000)
    }
    
    init(_ date: Date) {
        self.init(date.timeIntervalSince1970)
    }
    
    var date: Date { return Date(timeIntervalSince1970: interval) }
    var interval: TimeInterval { TimeInterval(value) / 1000 }
    
    public init(from decoder: ScaleDecoder) throws {
        value = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(value)
    }
}

extension Moment: ScaleDynamicCodable {}
