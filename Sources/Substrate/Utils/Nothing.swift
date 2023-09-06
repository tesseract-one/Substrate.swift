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

extension Nothing: Swift.Encodable, RuntimeSwiftEncodable, RuntimeDynamicSwiftEncodable {
    public func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

extension Nothing: Swift.Decodable, RuntimeSwiftDecodable, RuntimeDynamicSwiftDecodable {
    public init(from decoder: Swift.Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard container.decodeNil() else {
            throw Swift.DecodingError.dataCorruptedError(in: container,
                                                         debugDescription: "Must be null. Found some value")
        }
    }
}

extension Nothing: ScaleCodec.Codable, RuntimeCodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {}
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {}
}

extension Nothing: ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: type).get()
        return .nil(type.id)
    }
}

extension Nothing: VoidValueRepresentable {
    public func asValue() -> Value<Void> { .nil }
}

extension Nothing: IdentifiableType {
    @inlinable public static var definition: TypeDefinition { .void }
}

// Somehow substrate has Compact<()> type
extension Nothing: CompactCodable {
    public typealias UI = UInt8
    @inlinable public init(uint: UInt8) { self.init() }
    @inlinable public init?(trimmedLittleEndianData: Data) {
        guard trimmedLittleEndianData.count == 0 else { return nil }
        self.init()
    }
    @inlinable public var uint: UInt8 { 0 }
    @inlinable public var trimmedLittleEndianData: Data { Data() }
    @inlinable public var compactBitsUsed: Int { 0 }
    @inlinable public static var compactBitWidth: Int { 0 }
}
