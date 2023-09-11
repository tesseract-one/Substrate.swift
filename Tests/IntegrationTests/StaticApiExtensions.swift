//
//  StaticApiExtensions.swift
//  
//
//  Created by Yehor Popovych on 12/09/2023.
//

import Foundation
import Substrate

struct TransactionApi<R: RootApi<Configs.Substrate>>: RuntimeCallApi {
    typealias Api = Configs.Substrate.TransactionPaymentApi
    
    var api: R!
    init(api: R) { self.api = api }
    
    func queryInfo<C: Call>(extrinsic: ST<R.RC>.SignedExtrinsic<C>) async throws -> Api.QueryInfo.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = Api.QueryInfo(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
    
    func queryInfo<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra>, from: any PublicKey
    ) async throws -> Api.QueryInfo.TReturn {
        let signed = try await tx.fakeSign(account: from)
        return try await queryInfo(tx: signed)
    }
    
    func queryInfo<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicSignedExtra>
    ) async throws -> Api.QueryInfo.TReturn {
        try await queryInfo(extrinsic: tx.extrinsic)
    }
    
    func queryFeeDetails<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra>, from: any PublicKey
    ) async throws -> Api.QueryFeeDetails.TReturn {
        let signed = try await tx.fakeSign(account: from)
        return try await queryFeeDetails(tx: signed)
    }
    
    func queryFeeDetails<C: Call>(
        tx: Submittable<R, C, ST<R.RC>.ExtrinsicSignedExtra>
    ) async throws -> Api.QueryFeeDetails.TReturn {
        try await queryFeeDetails(extrinsic: tx.extrinsic)
    }
    
    func queryFeeDetails<C: Call>(
        extrinsic: ST<R.RC>.SignedExtrinsic<C>
    ) async throws -> Api.QueryFeeDetails.TReturn {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: api.runtime)
        let call = Api.QueryFeeDetails(extrinsic: encoder.output)
        return try await api.call.execute(call: call)
    }
}

extension RuntimeCallApiRegistry where R.RC == Configs.Substrate {
    var transaction: TransactionApi<R> { getApi(TransactionApi.self) }
}


struct BalancesApi<R: RootApi<Configs.Substrate>>: ExtrinsicApi {
    typealias Api = Configs.Substrate.Balances
    
    var api: R!
    init(api: R) { self.api = api }
    
    func transferAllowDeath(
        dest: ST<R.RC>.Address, value: Api.Types.Balance
    ) async throws -> Submittable<R, Api.Call.TransferAllowDeath, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await api.tx.new(Api.Call.TransferAllowDeath(dest: dest, value: value))
    }
}

extension ExtrinsicApiRegistry where R.RC == Configs.Substrate {
    var balances: BalancesApi<R> { getApi(BalancesApi.self) }
}
