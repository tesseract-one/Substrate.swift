//
//  Module.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation

public protocol Module {
    static var NAME: String { get }
    
    func registerEventsCallsAndTypes<R: TypeRegistryProtocol>(in registry: inout R) throws
}
