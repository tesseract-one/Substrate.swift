//
//  AnyEvent.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyEvent: Event, RuntimeDynamicValidatable, CustomStringConvertible {
    public let pallet: String
    public let name: String
    
    public let params: Value<NetworkType.Id>
    
    public init(name: String, pallet: String, params: Value<NetworkType.Id>) {
        self.pallet = pallet
        self.name = name
        self.params = params
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: NetworkType.Id,
                                       runtime: Runtime) throws
    {
        var value = try Value(from: &decoder, as: type, runtime: runtime)
        let pallet: String
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            guard values.count == 1 else {
                throw EventDecodingError.tooManyFieldsInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw EventDecodingError.tooManyFieldsInVariant(variant: value, expected: 1)
            }
            pallet = name
            value = fields.values.first!
        default: throw EventDecodingError.decodedNonVariantValue(value)
        }
        switch value.value {
        case .variant(.sequence(name: let name, values: let values)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .sequence(values), context: value.context))
        case .variant(.map(name: let name, fields: let fields)):
            self.init(name: name,
                      pallet: pallet,
                      params: Value(value: .map(fields), context: value.context))
        default: throw EventDecodingError.decodedNonVariantValue(value)
        }
    }
    
    public static func fetchEventData<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime, type: NetworkType.Id
    ) throws -> (name: String, pallet: String, data: Data) {
        let size = try Value<Void>.calculateSize(in: decoder, for: type, runtime: runtime)
        let hBytes = try decoder.peek(count: 2)
        guard let header = runtime.resolve(eventName: hBytes[1], pallet: hBytes[0]) else {
            throw EventDecodingError.eventNotFound(index: hBytes[1], pallet: hBytes[0])
        }
        return try (name: header.name, pallet: header.pallet, data: decoder.read(count: size))
    }
    
    public static func validate(runtime: Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError>
    {
        return Result { try runtime.types.event }
            .mapError { .runtimeTypeLookupFailed(name: "event", reason: $0) }
            .flatMap { $0.id == id ? .success(()) : .failure(.typeIdMismatch(got: id, has: $0.id)) }
    }
    
    public var description: String {
        "\(pallet).\(name)(\(params))"
    }
}
