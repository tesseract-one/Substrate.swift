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

extension Nothing: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

extension Nothing: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard container.decodeNil() else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Must be null. Found some value")
        }
    }
}

extension Nothing: ScaleCodable, ScaleRuntimeDecodable {
    public init(from decoder: ScaleCodec.ScaleDecoder) throws {}
    public func encode(in encoder: ScaleCodec.ScaleEncoder) throws {}
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
