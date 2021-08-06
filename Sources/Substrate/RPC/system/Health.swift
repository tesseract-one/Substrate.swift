//
//  Health.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct Health: Codable {
    public let peers: UInt64
    public let isSyncing: Bool
    public let shouldHavePeers: Bool
}
