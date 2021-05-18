//
//  RuntimeVersion.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public struct RuntimeVersion: Decodable {
    public let specName: String
    public let implName: String
    public let authoringVersion: UInt32
    public let specVersion: UInt32
    public let implVersion: UInt32
    public let apis: [Api]
    public let transactionVersion: UInt32
    
    public struct Api: Decodable {
        public let id: Data
        public let version: UInt32
        
        public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            id = try container.decode(Data.self)
            version = try container.decode(UInt32.self)
        }
    }
}
