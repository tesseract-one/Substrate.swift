//
//  Nothing.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation
import ScaleCodec

public struct Nothing: Hashable, Equatable, CustomStringConvertible, ExpressibleByNilLiteral {
    public init() {}
    public init(nilLiteral: ()) {}
    public var description: String { "()" }
    public static let nothing = Nothing()
}

extension Nothing: Swift.Encodable {
    public func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

extension Nothing: Swift.Decodable {
    public init(from decoder: Swift.Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard container.decodeNil() else {
            throw Swift.DecodingError.dataCorruptedError(in: container,
                                                         debugDescription: "Must be null. Found some value")
        }
    }
}

extension Nothing: ScaleCodec.Codable, RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {}
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {}
}

extension Nothing: ValueConvertible {
    public init<C>(value: Value<C>) throws {
        switch value.value {
        case .sequence(let vals):
            guard vals.count == 0 else {
                throw ValueInitializableError<C>.wrongValuesCount(in: value.value,
                                                                  expected: 0,
                                                                  for: "Nothing")
            }
        case .map(let fields):
            guard fields.count == 0 else {
                throw ValueInitializableError<C>.wrongValuesCount(in: value.value,
                                                                  expected: 0,
                                                                  for: "Nothing")
            }
        default:
            throw ValueInitializableError<C>.wrongValueType(got: value.value, for: "Nothing")
        }
    }
    
    public func asValue() throws -> Value<Void> { .sequence([]) }
}
