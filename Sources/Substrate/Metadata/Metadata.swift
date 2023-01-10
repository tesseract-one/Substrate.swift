//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation

public protocol Metadata {
    var version: UInt8 { get }
    var types: [RuntimeTypeInfo] { get }
}

