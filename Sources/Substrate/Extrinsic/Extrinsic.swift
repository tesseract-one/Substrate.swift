//
//  Extrinsic.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec

public struct Extrinsic<C: Call, Extra: ExtrinsicExtra>: CustomStringConvertible, CallHolder {
    public typealias TCall = C
    
    public let call: C
    public let extra: Extra
    
    @inlinable
    public var isSigned: Bool { extra.isSigned }
    
    @inlinable
    public init(call: C, extra: Extra) {
        self.call = call
        self.extra = extra
    }
    
    public var description: String {
        "\(isSigned ? "SignedExtrinsic" : "UnsignedExtrinsic")(call: \(call), extra: \(extra))"
    }
}

public protocol ExtrinsicExtra {
    var isSigned: Bool { get }
}

public struct ExtrinsicSignPayload<C: Call, Extra>: CustomStringConvertible, CallHolder {
    public typealias TCall = C
    
    public let call: C
    public let extra: Extra
    
    @inlinable
    public init(call: C, extra: Extra) {
        self.call = call
        self.extra = extra
    }
    
    public var description: String {
        "ExtrinsicPayload(call: \(call), extra: \(extra))"
    }
}

extension Nothing: ExtrinsicExtra {
    public var isSigned: Bool { false }
}

extension Either: ExtrinsicExtra where Left: ExtrinsicExtra, Right: ExtrinsicExtra {
    public var isSigned: Bool {
        switch self {
        case .left(let l): return l.isSigned
        case .right(let r): return r.isSigned
        }
    }
}

public protocol OpaqueExtrinsic<THash, TSignedExtra, TUnsignedExtra>: RuntimeSwiftDecodable, ValidatableType {
    associatedtype THash: Hash
    associatedtype TSignedExtra: ExtrinsicExtra
    associatedtype TUnsignedExtra: ExtrinsicExtra
    
    func hash() -> THash
    
    func decode<C: Call & RuntimeDecodable>() throws -> Extrinsic<C, Either<TUnsignedExtra, TSignedExtra>>
    
    static var version: UInt8 { get }
}


public protocol SomeExtrinsicEra: RuntimeDynamicCodable, ValueRepresentable, ValidatableType, Default {
    var isImmortal: Bool { get }
    
    func blockHash<R: RootApi>(api: R) async throws -> R.RC.TBlock.THeader.THasher.THash
    
    static var immortal: Self { get }
}

public extension SomeExtrinsicEra {
    static var `default`: Self { Self.immortal }
}

public enum ExtrinsicCodingError: Error {
    case badExtrinsicVersion(supported: UInt8, got: UInt8)
    case badExtrasCount(expected: Int, got: Int)
    case parameterNotFound(extension: ExtrinsicExtensionId, parameter: String)
    case typeMismatch(expected: Any.Type, got: Any.Type)
    case unknownExtension(identifier: ExtrinsicExtensionId)
}

public protocol SomeExtrinsicFailureEvent: PalletEvent {
    associatedtype Err: Error
    var error: Err { get }
}

public protocol SomeDispatchError: CallError {
    associatedtype TModuleError: Error
    var isModuleError: Bool { get }
    var moduleError: TModuleError { get throws }
}

public struct ModuleError: Error, IdentifiableType {
    public let pallet: PalletMetadata
    public let error: NetworkType.Variant
    
    public init(values: [Value<NetworkType.Id>], runtime: any Runtime) throws {
        guard values.count == 2 else {
            throw FrameTypeError.wrongFieldsCount(for: "ModuleError", expected: 2,
                                                  got: values.count)
        }
        guard let index = values[0].uint.flatMap({UInt8(exactly: $0)}) else {
            throw FrameTypeError.paramMismatch(for: "Error", index: 0,
                                               expected: "UInt8", got: values[0].description)
        }
        guard let bytes = values[1].bytes, bytes.count > 0 else {
            throw FrameTypeError.paramMismatch(for: "Error", index: 1,
                                               expected: "Data", got: values[1].description)
        }
        try self.init(pallet: index, error: bytes[0], metadata: runtime.metadata)
    }
    
    public init(pallet: UInt8, error: UInt8, metadata: any Metadata) throws {
        guard let pallet = metadata.resolve(pallet: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: "Error", index: error, frame: pallet)
        }
        guard let palletError = pallet.error else {
            throw FrameTypeError.paramMismatch(for: "\(pallet.name).error",
                                               index: -1, expected: "NetworkType.Info",
                                               got: "nil")
        }
        guard case .variant(variants: let variants) = palletError.type.definition else {
            throw FrameTypeError.wrongType(for: "\(pallet.name).error",
                                           got: palletError.type.description,
                                           reason: "Should be Variant")
        }
        guard let error = variants.first(where: { $0.index == error }) else {
            throw FrameTypeError.typeInfoNotFound(for: "Error", index: error,
                                                  frame: pallet.index)
        }
        self.pallet = pallet
        self.error = error
    }
    
    public static var definition: TypeDefinition {
        .composite(fields: [.v(UInt8.definition), .v(.data(count: 4))])
    }
}

