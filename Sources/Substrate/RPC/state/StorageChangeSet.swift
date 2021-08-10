//
//  StorageChangeSet.swift
//  
//
//  Created by Yehor Popovych on 10.08.2021.
//

import Foundation
import ScaleCodec

public struct StorageChangeSet<H: Hash> {
    public let block: H
    // TODO: Provide better typisation (DYNAMIC)
    public let changes: Array<(AnyStorageKey, Optional<Any>)>
}

struct StorageChangeSetData<H: Hash>: Codable {
    public let block: H
    public let changes: Array<Array<Data>>
    
    func parse(registry: TypeRegistryProtocol) throws -> StorageChangeSet<H> {
        let mChanges = try changes.map { change -> (AnyStorageKey, Optional<Any>) in
            let key = try registry.decode(keyFrom: SCALE.default.decoder(data: change[0]))
            let val = change.count > 1
                ? try key.decode(valueFrom: SCALE.default.decoder(data: change[1]), registry: registry)
                : nil
            return (key, val)
        }
        return StorageChangeSet(block: block, changes: mChanges)
    }
}
