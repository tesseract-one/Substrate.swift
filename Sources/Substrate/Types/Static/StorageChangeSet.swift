//
//  StorageChangeSet.swift
//  
//
//  Created by Yehor Popovych on 15/06/2023.
//

import Foundation

public struct StorageChangeSet<H: Hash>: SomeStorageChangeSet {
    public typealias THash = H
    public let block: H
    public let changes: [(key: Data, value: Data?)]
    
    enum CodingKeys: String, CodingKey {
        case block
        case changes
    }
    
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let block = try container.decode(H.self, forKey: .block) { try runtime.types.hash.get() }
        var changesContainer = try container.nestedUnkeyedContainer(forKey: .changes)
        var changes: [(key: Data, value: Data?)] = []
        if let count = changesContainer.count {
            changes.reserveCapacity(count)
        }
        while !changesContainer.isAtEnd {
            var change = try changesContainer.nestedUnkeyedContainer()
            try changes.append((change.decode(Data.self), change.decode(Optional<Data>.self)))
        }
        self.block = block
        self.changes = changes
    }
}
