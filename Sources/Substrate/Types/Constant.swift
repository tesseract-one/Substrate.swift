//
//  Constant.swift
//  
//
//  Created by Yehor Popovych on 12/09/2023.
//

import Foundation
import ScaleCodec

public protocol StaticConstant: FrameType {
    associatedtype TValue
    static var pallet: String { get }
    static func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D,
                                              runtime: any Runtime) throws -> TValue
}

public extension StaticConstant {
    @inlinable static var frame: String { pallet }
}

public extension StaticConstant where TValue: RuntimeDecodable {
    static func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D,
                                              runtime: any Runtime) throws -> TValue
    {
        try TValue(from: &decoder, runtime: runtime)
    }
}

public extension StaticConstant where TValue: ValidatableTypeStatic {
    static func validate(runtime: any Runtime) -> Result<Void, FrameTypeError> {
        guard let info = runtime.resolve(constant: name, pallet: pallet) else {
            return .failure(.typeInfoNotFound(for: Self.self, .get()))
        }
        return TValue.validate(as: info.type, in: runtime).mapError {
            .childError(for: Self.self, index: -1, error: $0, .get())
        }
    }
}

public extension StaticConstant where TValue: IdentifiableTypeStatic {
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .constant(type: registry.def(TValue.self))
    }
}
