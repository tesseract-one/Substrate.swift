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
    ) async throws where RPC: RpcCallableClient & RuntimeHolder, CL == RpcClient<RC, RPC> {
        let systemClient = RpcClient<RC, RPC>(client: client)
        try await self.init(client: systemClient, config: config, signer: signer, at: hash)
    }
}
