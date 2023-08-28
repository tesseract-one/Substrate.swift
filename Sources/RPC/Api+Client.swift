//
//  Api+Client.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
import Substrate

public extension Api {
    convenience init<RPC>(
        rpc client: RPC, config: RC, signer: Signer? = nil, at hash: ST<RC>.Hash? = nil
    ) async throws where RPC: RpcCallableClient, CL == RpcClient<RC, RPC> {
        let systemClient = RpcClient<RC, RPC>(client: client)
        try await self.init(client: systemClient, config: config, signer: signer, at: hash)
    }
    
    convenience init<RPC, Ext>(
        rpc client: RPC, config: Configs.Registry<RC, Ext>, signer: Signer? = nil, at hash: ST<RC>.Hash? = nil
    ) async throws where RPC: RpcCallableClient, CL == RpcClient<RC, RPC> {
        let systemClient = RpcClient<RC, RPC>(client: client)
        try await self.init(client: systemClient, config: config, signer: signer, at: hash)
    }
}

public extension Api where CL == RpcClient<RC, JsonRpcCallableClient> {
    func fork<C: Config>(config: C) async throws -> Api<C, RpcClient<C, JsonRpcCallableClient>>
        where ST<C>.Hash == ST<RC>.Hash
    {
        let client = RpcClient<C, JsonRpcCallableClient>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
    
    func fork<C: Config>(
        at hash: ST<C>.Hash?, config: C
    ) async throws -> Api<C, RpcClient<C, JsonRpcCallableClient>> {
        let client = RpcClient<C, JsonRpcCallableClient>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
}

public extension Api where CL == RpcClient<RC, JsonRpcSubscribableClient> {
    func fork<C: Config>(config: C) async throws -> Api<C, RpcClient<C, JsonRpcSubscribableClient>>
        where ST<C>.Hash == ST<RC>.Hash
    {
        let client = RpcClient<C, _>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
    
    func fork<C: Config>(
        at hash: ST<C>.Hash?, config: C
    ) async throws -> Api<C, RpcClient<C, JsonRpcSubscribableClient>> {
        let client = RpcClient<C, _>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
}
