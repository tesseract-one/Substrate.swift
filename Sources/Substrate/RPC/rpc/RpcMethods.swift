//
//  RpcMethods.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct RpcMethods: Codable {
    public let version: UInt32
    public let methods: Array<String>
}
