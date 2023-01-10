//
//  ReistryCodable.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import ScaleCodec

public protocol RegistryScaleEncodable {
    func encode(in encoder: ScaleEncoder, registry: Registry) throws
}

public protocol RegistryScaleDecodable {
    init(from decoder: ScaleDecoder, registry: Registry) throws
}

public typealias RegistryScaleCodable = RegistryScaleEncodable & RegistryScaleDecodable

extension ScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder)
    }
}

extension ScaleDecodable {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        try self.init(from: decoder)
    }
}

public protocol RegistryScaleDynamicEncodable {
    func encode(in encoder: ScaleEncoder, `as` type: RuntimeTypeId, registry: Registry) throws
}

public protocol RegistryScaleDynamicDecodable {
    init(from decoder: ScaleDecoder, `as` type: RuntimeTypeId, registry: Registry) throws
}
