//
//  Event.swift
//  
//
//  Created by Yehor Popovych on 13.02.2023.
//

import Foundation
import ScaleCodec

public protocol Event: RuntimeDynamicDecodable {
    var pallet: String { get }
    var name: String { get }
}

public protocol PalletEvent: Event, FrameType {
    static var pallet: String { get }
}

public extension PalletEvent {
    @inlinable var pallet: String { Self.pallet }
    @inlinable var frame: String { pallet }
    @inlinable static var frame: String { pallet }
    @inlinable static var frameTypeName: String { "Event" }
}

public typealias EventTypeInfo = [TypeDefinition.Field]
public typealias EventChildTypes = [ValidatableTypeStatic.Type]

public extension PalletEvent where
    Self: ComplexFrameType, TypeInfo == EventTypeInfo
{
    static func typeInfo(runtime: any Runtime) -> Result<TypeInfo, FrameTypeError> {
        guard let info = runtime.resolve(eventParams: name, pallet: pallet) else {
            return .failure(.typeInfoNotFound(for: Self.self, .get()))
        }
        return .success(info)
    }
}

public protocol StaticEvent: PalletEvent, RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(paramsFrom decoder: inout D, runtime: Runtime) throws
}

public extension StaticEvent {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let evIndex = try decoder.decode(UInt8.self)
        guard let info = runtime.resolve(eventName: evIndex, pallet: modIndex) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, index: evIndex,
                                                  frame: modIndex, .get())
        }
        guard Self.frame == info.pallet && Self.name == info.name else {
            throw FrameTypeError.foundWrongType(for: Self.self, name: info.name,
                                                frame: info.pallet, .get())
        }
        try self.init(paramsFrom: &decoder, runtime: runtime)
    }
}

public protocol SomeEventRecord: RuntimeDynamicDecodable, ValidatableType {
    var extrinsicIndex: UInt32? { get }
    var header: (name: String, pallet: String) { get }
    var any: AnyEvent { get throws }
    func typed<E: PalletEvent>(_ type: E.Type) throws -> E
}
