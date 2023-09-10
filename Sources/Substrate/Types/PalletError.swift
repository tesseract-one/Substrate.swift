//
//  PalletError.swift
//  
//
//  Created by Yehor Popovych on 10/09/2023.
//

import Foundation

public protocol PalletError: Error, RuntimeDecodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol StaticPalletError: PalletError, FrameType {
    var pallet: String { get }
    static var pallet: String { get }
}

public extension StaticPalletError {
    @inlinable var pallet: String { Self.pallet }
    @inlinable var frame: String { pallet }
    @inlinable static var frame: String { pallet }
    @inlinable static var frameTypeName: String { "Error" }
}

public typealias ErrorTypeInfo = [TypeDefinition.Field]
public typealias ErrorChildTypes = [ValidatableTypeStatic.Type]

public extension StaticPalletError where
    Self: ComplexFrameType, TypeInfo == ErrorTypeInfo
{
    static func typeInfo(from runtime: any Runtime) -> Result<TypeInfo, FrameTypeError> {
        guard let error = runtime.resolve(palletError: pallet) else {
            return .failure(.typeInfoNotFound(for: Self.self, .get()))
        }
        guard case .variant(variants: let vars) = error.type.flatten().definition else {
            return .failure(.foundWrongType(for: Self.self, name: "", frame: pallet, .get()))
        }
        guard let vrt = vars.first(where: { $0.name == name }) else {
            return .failure(.typeInfoNotFound(for: Self.self, .get()))
        }
        return .success(vrt.fields)
    }
}
