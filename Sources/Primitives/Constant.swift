//
//  Constant.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation

public protocol AnyConstant {
    associatedtype Value
    
    var module: String { get }
    var name: String { get }
}

public protocol Constant: AnyConstant where Value: ScaleDynamicDecodable {
    associatedtype Module: ModuleProtocol
    
    static var MODULE: String { get }
    static var NAME: String { get }
}

extension Constant {
    public static var MODULE: String { Module.NAME }
    public var module: String { Self.MODULE }
    public var name: String { Self.NAME }
}

public protocol DynamicConstant: AnyConstant where Value == DValue {}

public struct DConstant: DynamicConstant {
    public typealias Value = DValue

    public var module: String
    public var name: String
    
    public init(module: String, name: String) {
        self.module = module
        self.name = name
    }
}
