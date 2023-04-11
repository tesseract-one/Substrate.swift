//
//  RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import ScaleCodec

public protocol ScaleRuntimeEncodable {
    func encode(in encoder: ScaleEncoder, runtime: Runtime) throws
}

public protocol ScaleRuntimeDecodable {
    init(from decoder: ScaleDecoder, runtime: Runtime) throws
}

public typealias ScaleRuntimeCodable = ScaleRuntimeEncodable & ScaleRuntimeDecodable

extension ScaleEncodable {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder)
    }
}

extension ScaleDecodable {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder)
    }
}

public protocol ScaleRuntimeDynamicEncodable {
    func encode(in encoder: ScaleEncoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public protocol ScaleRuntimeDynamicDecodable {
    init(from decoder: ScaleDecoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public protocol RuntimeDynamicDecodable {
    init(from decoder: Decoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}
