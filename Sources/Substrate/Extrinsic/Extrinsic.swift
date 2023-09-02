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

public protocol OpaqueExtrinsic<THash, TSignedExtra, TUnsignedExtra>: RuntimeSwiftDecodable {
    associatedtype THash: Hash
    associatedtype TSignedExtra: ExtrinsicExtra
    associatedtype TUnsignedExtra: ExtrinsicExtra
    
    func hash() -> THash
    
    func decode<C: Call & RuntimeDynamicDecodable>() throws -> Extrinsic<C, Either<TUnsignedExtra, TSignedExtra>>
    
    static var version: UInt8 { get }
}


public protocol SomeExtrinsicEra: RuntimeDynamicCodable, ValueRepresentable, RuntimeDynamicValidatable, Default {
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

public protocol SomeExtrinsicFailureEvent: IdentifiableEvent, RuntimeValidatable {
    associatedtype Err: Error
    var error: Err { get }
}

public protocol SomeDispatchError: CallError {
    associatedtype TModuleError: Error
    var isModuleError: Bool { get }
    var moduleError: TModuleError { get throws }
}

public struct ModuleError: Error {
    public enum DecodingError: Error {
        case dispatchErrorIsNotModule(description: String)
        case badModuleVariant(Value<NetworkType.Id>.Variant)
        case palletNotFound(index: UInt8)
        case badPalletError(type: NetworkType.Info?)
        case errorNotFound(index: UInt8)
    }
    
    public let pallet: PalletMetadata
    public let error: NetworkType.Variant
    
    public init(variant: Value<NetworkType.Id>.Variant, runtime: any Runtime) throws {
        let fields = variant.values
        guard fields.count == 2,
              let index = fields[0].uint.flatMap({UInt8(exactly: $0)}),
              let bytes = fields[1].bytes, bytes.count > 0 else
        {
            throw DecodingError.badModuleVariant(variant)
        }
        try self.init(pallet: index, error: bytes[0], metadata: runtime.metadata)
    }
    
    public init(pallet: UInt8, error: UInt8, metadata: any Metadata) throws {
        guard let pallet = metadata.resolve(pallet: pallet) else {
            throw DecodingError.palletNotFound(index: pallet)
        }
        guard case .variant(variants: let variants) = pallet.error?.type.definition else {
            throw DecodingError.badPalletError(type: pallet.error)
        }
        guard let error = variants.first(where: { $0.index == error }) else {
            throw DecodingError.errorNotFound(index: error)
        }
        self.pallet = pallet
        self.error = error
    }
    
    public static func validate(variant: NetworkType.Variant,
                                runtime: any Runtime) -> Bool
    {
        guard variant.fields.count == 2 else {
            return false
        }
        guard runtime.resolve(type: variant.fields[0].type)?.asPrimitive(runtime)?.isUInt == 8 else {
            return false
        }
        guard runtime.resolve(type: variant.fields[0].type)?.asBytes(runtime) ?? 0 > 0 else {
            return false
        }
        return true
    }
}

