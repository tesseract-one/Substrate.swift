//
//  AnyModuleError.swift
//  
//
//  Created by Yehor Popovych on 11/09/2023.
//

import Foundation
import ScaleCodec

public struct AnyModuleError: PalletError, Equatable {
    public let pallet: String
    public let name: String
    public let fields: [Value<TypeDefinition>]
    public let extra: Data
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let palletId = try decoder.decode(.enumCaseId)
        let errorId = try decoder.decode(.enumCaseId)
        let info = try Self.fetchInfo(error: errorId, pallet: palletId, runtime: runtime).get()
        let fields = try info.error.fields.map { try runtime.decodeValue(from: &decoder, type: *$0.type) }
        let extra = decoder.length > 0 ? try decoder.read(count: decoder.length) : Data()
        self.pallet = info.pallet
        self.name = info.error.name
        self.fields = fields
        self.extra = extra
    }
    
    public static func fetchInfo(
        error: UInt8, pallet: UInt8, runtime: any Runtime
    ) -> Result<(pallet: String, error: TypeDefinition.Variant), FrameTypeError> {
        guard let info = runtime.resolve(palletError: pallet) else {
            return .failure(.typeInfoNotFound(for: "\(Self.self)",
                                              index: 0,
                                              frame: pallet, .get()))
        }
        guard case .variant(variants: let vars) = info.type.flatten().definition else {
            return .failure(.wrongType(for: "\(Self.self)",
                                       got: info.type.description,
                                       reason: "Expected Variant", .get()))
        }
        guard let vrt = vars.first(where: { $0.index == error }) else {
            return .failure(.typeInfoNotFound(for: "\(Self.self)",
                                              index: error,
                                              frame: pallet, .get()))
        }
        return .success((info.pallet, vrt))
    }
    
    public static func fetchInfo(
        error: String, pallet: String, runtime: any Runtime
    ) -> Result<TypeDefinition.Variant, FrameTypeError> {
        guard let info = runtime.resolve(palletError: pallet) else {
            return .failure(.typeInfoNotFound(for: "\(Self.self)", .get()))
        }
        guard case .variant(variants: let vars) = info.type.flatten().definition else {
            return .failure(.wrongType(for: "\(Self.self)",
                                       got: info.type.description,
                                       reason: "Expected Variant", .get()))
        }
        guard let vrt = vars.first(where: { $0.name == error }) else {
            return .failure(.typeInfoNotFound(for: "\(Self.self)", .get()))
        }
        return .success(vrt)
    }
}
