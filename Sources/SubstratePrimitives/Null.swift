//
//  Null.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct SNull: ScaleCodable, Equatable, Hashable {
    public init() {}
    public init(from decoder: ScaleDecoder) throws {}
    public func encode(in encoder: ScaleEncoder) throws {}
}

extension SNull: ScaleRegistryCodable {}
