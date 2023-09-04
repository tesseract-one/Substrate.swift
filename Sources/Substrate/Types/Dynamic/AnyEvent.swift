//
//  AnyEvent.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyEvent: Event, ValidatableType, CustomStringConvertible {
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
                throw FrameTypeError.wrongFieldsCount(for: "AnyEvent", expected: 1,
                                                      got: values.count)
            }
            pallet = name
            value = values.first!
        case .variant(.map(name: let name, fields: let fields)):
            guard fields.count == 1 else {
                throw FrameTypeError.wrongFieldsCount(for: "AnyEvent", expected: 1,
                                                      got: fields.count)
            }
            pallet = name
            value = fields.values.first!
        default: throw FrameTypeError.paramMismatch(for: "AnyEvent",
                                                    index: 0,
                                                    expected: "Value.Variant",
                                                    got: value.description)
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
        default: throw FrameTypeError.paramMismatch(for: "AnyEvent: \(pallet)",
                                                    index: 0,
                                                    expected: "Value.Variant",
                                                    got: value.description)
        }
    }
    
    public static func fetchEventData<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: any Runtime, type: NetworkType.Id
    ) throws -> (name: String, pallet: String, data: Data) {
        let size = try Value<Void>.calculateSize(in: decoder, for: type, runtime: runtime)
        let hBytes = try decoder.peek(count: 2)
        guard let header = runtime.resolve(eventName: hBytes[1], pallet: hBytes[0]) else {
            throw FrameTypeError.typeInfoNotFound(for: "Event", index: hBytes[1], frame: hBytes[0])
        }
        return try (name: header.name, pallet: header.pallet, data: decoder.read(count: size))
    }
    
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        TypeDefinition.from(network: type.type.definition, runtime: runtime).flatMap { own in
            TypeDefinition.from(network: runtime.types.event.type.definition, runtime: runtime).flatMap {
                own == $0 ? .success(()) : .failure(.wrongType(for: Self.self, got: type.type,
                                                               reason: "event types is different"))
            }
        }
    }
    
    public var description: String {
        "\(pallet).\(name)(\(params))"
    }
}
