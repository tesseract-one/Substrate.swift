//
//  Api.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc

public protocol SubstrateApi {
    associatedtype S: SubstrateProtocol
    
    static var id: String { get }
    
    init(substrate: S)
}

extension SubstrateApi {
    public static var id: String { String(describing: self) }
}
