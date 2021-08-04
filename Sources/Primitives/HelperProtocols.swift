//
//  HelperProtocols.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec

public protocol BlockNumberProtocol: ScaleDynamicCodable, SDefault, Equatable {
    static var firstBlock: Self { get }
    
    // special methods to avoid breaking of type default Codable
    init(jsonData: Data) throws
    var jsonData: Data { get }
}

extension UnsignedInteger {
    public static var firstBlock: Self { 0 }
}

extension UInt32: BlockNumberProtocol {
    public init(jsonData: Data) throws {
        try self.init(decoding: jsonData)
    }
    
    public var jsonData: Data {
        try! encode()
    }
}

extension UInt64: BlockNumberProtocol {
    public init(jsonData: Data) throws {
        try self.init(decoding: jsonData)
    }

    public var jsonData: Data {
        try! encode()
    }
}
