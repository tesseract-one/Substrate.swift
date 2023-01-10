//
//  BitVec.swift
//  
//
//  Created by Yehor Popovych on 10/9/20.
//

import Foundation
import ScaleCodec

public struct BitVec: ScaleCodable {
    public let values: [UInt8]
    
    public init(_ values: [UInt8]) {
        self.values = values
    }
    
    public init(_ data: Data) {
        values = Array(data)
    }
    
    public init(from decoder: ScaleDecoder) throws {
        let size: UInt32 = try decoder.decode(.compact)
        let data: Data = try decoder.decode(.fixed(UInt(size) / 8))
        self.init(data)
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder
            .encode(UInt32(values.count * 8), .compact)
            .encode(Data(values), .fixed(UInt(values.count)))
    }
}

extension BitVec: RegistryScaleCodable {}
