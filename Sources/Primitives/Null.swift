//
//  Null.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct DNull: ScaleCodable, Equatable, Hashable, Error {
    public init() {}
    public init(from decoder: ScaleDecoder) throws {}
    public func encode(in encoder: ScaleEncoder) throws {}
}

extension DNull: ScaleDynamicCodable {}

extension DNull: ScaleDynamicEncodableOptionalConvertible {
    public var encodableOptional: DEncodableOptional {
        return .none
    }
}
