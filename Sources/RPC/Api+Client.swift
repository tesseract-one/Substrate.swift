//
//  Api+Client.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation
#if !COCOAPODS
import Substrate
#endif

public extension Api {
    convenience init<RPC>(
        rpc client: RPC, config: RC, signer: Signer? = nil, at hash: RC.THasher.THash? = nil
    ) async throws where RPC: RpcCallableClient, CL == RpcClient<RC, RPC> {
        let systemClient = RpcClient<RC, RPC>(client: client)
        try await self.init(client: systemClient, config: config, signer: signer, at: hash)
    }
    
    convenience init<RPC>(
        rpc client: RPC, config: ConfigRegistry<RC>, signer: Signer? = nil, at hash: RC.THasher.THash? = nil
    ) async throws where RPC: RpcCallableClient, CL == RpcClient<RC, RPC> {
        let systemClient = RpcClient<RC, RPC>(client: client)
        try await self.init(client: systemClient, config: config, signer: signer, at: hash)
    }
}

public extension Api where CL == RpcClient<RC, JsonRpcCallableClient> {
    func fork<C: Config>(config: C) async throws -> Api<C, RpcClient<C, JsonRpcCallableClient>>
        where C.THasher.THash == RC.THasher.THash
    {
        let client = RpcClient<C, JsonRpcCallableClient>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
    
    func fork<C: Config>(
        at hash: C.THasher.THash?, config: C
    ) async throws -> Api<C, RpcClient<C, JsonRpcCallableClient>> {
        let client = RpcClient<C, JsonRpcCallableClient>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
}

public extension Api where CL == RpcClient<RC, JsonRpcSubscribableClient> {
    func fork<C: Config>(config: C) async throws -> Api<C, RpcClient<C, JsonRpcSubscribableClient>>
        where C.THasher.THash == RC.THasher.THash
    {
        let client = RpcClient<C, _>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
    
    func fork<C: Config>(
        at hash: C.THasher.THash?, config: C
    ) async throws -> Api<C, RpcClient<C, JsonRpcSubscribableClient>> {
        let client = RpcClient<C, _>(client: self.client.client)
        return try await Api<_, _>(client: client, config: config, signer: signer, at: hash)
    }
}
