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

public protocol IdentifiableEvent: Event, PalletType {}

public protocol StaticEvent: IdentifiableEvent, RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(paramsFrom decoder: inout D, runtime: Runtime) throws
}

public extension StaticEvent {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(UInt8.self)
        let evIndex = try decoder.decode(UInt8.self)
        guard let info = runtime.resolve(eventName: evIndex, pallet: modIndex) else {
            throw EventDecodingError.eventNotFound(index: evIndex, pallet: modIndex)
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw EventDecodingError.foundWrongEvent(found: (name: info.name, pallet: info.pallet),
                                                     expected: (name: Self.name, pallet: Self.pallet))
        }
        try self.init(paramsFrom: &decoder, runtime: runtime)
    }
}

public extension IdentifiableEvent where Self: RuntimeValidatableComposite {
    static func validatableFieldIds(runtime: any Runtime) -> Result<[NetworkType.Id], ValidationError> {
        guard let info = runtime.resolve(eventParams: name, pallet: pallet) else {
            return .failure(.infoNotFound(for: Self.self))
        }
        return .success(info.map{$0.type})
    }
}

public protocol SomeEventRecord: RuntimeDynamicDecodable, RuntimeDynamicValidatable {
    var extrinsicIndex: UInt32? { get }
    var header: (name: String, pallet: String) { get }
    var any: AnyEvent { get throws }
    func typed<E: IdentifiableEvent>(_ type: E.Type) throws -> E
}

public enum EventDecodingError: Error {
    case eventNotFound(index: UInt8, pallet: UInt8)
    case foundWrongEvent(found: (name: String, pallet: String), expected: (name: String, pallet: String))
    case decodedNonVariantValue(Value<NetworkType.Id>)
    case tooManyFieldsInVariant(variant: Value<NetworkType.Id>, expected: Int)
}
