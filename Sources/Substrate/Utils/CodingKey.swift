//
//  CodingKey.swift
//  
//
//  Created by Yehor Popovych on 06.01.2023.
//

import Foundation

public struct AnyCodableCodingKey: CodingKey, Equatable {
    public let stringValue: String
    public let intValue: Int?
    
    public init(_ string: String) {
        self.stringValue = string
        self.intValue = nil
    }
    
    public init(_ int: Int) {
        self.stringValue = String(int)
        self.intValue = int
    }
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

public struct CodableComplexKey<T: Equatable>: CodingKey, Equatable {
    public var stringValue: String
    public var intValue: Int?
    
    public init(_ string: String) {
        self.stringValue = string
        self.intValue = nil
    }
    
    public init(_ int: Int) {
        self.stringValue = String(int)
        self.intValue = int
    }
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }

    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
