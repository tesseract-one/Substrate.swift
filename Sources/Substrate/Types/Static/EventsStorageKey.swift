//
//  EventsStorageKey.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation

public struct EventsStorageKey<BE: SomeBlockEvents & RuntimeDecodable>: PlainStorageKey {
    public typealias TParams = Void
    public typealias TBaseParams = Void
    public typealias TValue = BE
    
    public static var pallet: String { "System" }
    public static var name: String { "Events" }
    
    public init() {}
}
