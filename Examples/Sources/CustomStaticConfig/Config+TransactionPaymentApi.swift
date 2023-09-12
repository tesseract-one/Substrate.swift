//
//  Config+TransactionPaymentApi.swift
//  
//
//  Created by Yehor Popovych on 13/09/2023.
//

import Foundation
import Substrate
import ScaleCodec

extension Config {
    struct TransactionPaymentApi: RuntimeApiFrame {
        static var name: String = "TransactionPaymentApi"
        
        var calls: [any StaticRuntimeCall.Type] {
            [QueryInfo.self, QueryFeeDetails.self]
        }
        
        struct QueryInfo: RuntimeApiFrameCall, IdentifiableFrameType {
            typealias TApi = TransactionPaymentApi
            typealias TReturn = ST<Config>.RuntimeDispatchInfo
            
            static var method: String = "query_info"
            
            let uxt: Data
            let len: UInt32
            
            public init(extrinsic: Data) {
                uxt = extrinsic
                len = UInt32(extrinsic.count)
            }
            
            func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
                try encoder.encode(uxt, .fixed(UInt(len)))
                try encoder.encode(len)
            }
            
            static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                .runtimeCall(params: [
                    .v(registry.def(Data.self, .dynamic)),
                    .v(registry.def(UInt32.self))
                ], return: registry.def(ST<Config>.RuntimeDispatchInfo.self))
            }
        }
        
        struct QueryFeeDetails: RuntimeApiFrameCall, IdentifiableFrameType {
            typealias TApi = TransactionPaymentApi
            typealias TReturn = ST<Config>.FeeDetails
            
            static var method: String = "query_fee_details"
            
            let uxt: Data
            let len: UInt32
            
            public init(extrinsic: Data) {
                uxt = extrinsic
                len = UInt32(extrinsic.count)
            }
            
            func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
                try encoder.encode(uxt, .fixed(UInt(len)))
                try encoder.encode(len)
            }
            
            static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
                .runtimeCall(params: [
                    .v(registry.def(Data.self, .dynamic)),
                    .v(registry.def(UInt32.self))
                ], return: registry.def(ST<Config>.FeeDetails.self))
            }
        }
    }
}

extension RuntimeCallApiRegistry where R.RC == Config {
    var transaction: FrameRuntimeCallApi<R, Config.TransactionPaymentApi> { _frame() }
}

extension FrameRuntimeCallApi where R.RC == Config,
                                    F == Config.TransactionPaymentApi
{
    func queryInfo<C: Call>(extrinsic: ST<R.RC>.SignedExtrinsic<C>) async throws -> F.QueryInfo.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = F.QueryInfo(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
    
    func queryInfo<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra>, from: any PublicKey
    ) async throws -> F.QueryInfo.TReturn {
        let signed = try await tx.fakeSign(account: from)
        return try await queryInfo(tx: signed)
    }
    
    func queryInfo<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicSignedExtra>
    ) async throws -> F.QueryInfo.TReturn {
        try await queryInfo(extrinsic: tx.extrinsic)
    }
    
    func queryFeeDetails<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra>, from: any PublicKey
    ) async throws -> F.QueryFeeDetails.TReturn {
        let signed = try await tx.fakeSign(account: from)
        return try await queryFeeDetails(tx: signed)
    }
    
    func queryFeeDetails<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicSignedExtra>
    ) async throws -> F.QueryFeeDetails.TReturn {
        try await queryFeeDetails(extrinsic: tx.extrinsic)
    }
    
    func queryFeeDetails<C: Call>(
        extrinsic: ST<R.RC>.SignedExtrinsic<C>
    ) async throws -> F.QueryFeeDetails.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = F.QueryFeeDetails(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
}
