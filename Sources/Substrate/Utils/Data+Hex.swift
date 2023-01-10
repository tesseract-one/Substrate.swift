//
//  Data+Hex.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation
import JsonRPC

public extension Data {
    init?(hex: String) {
        guard let result = Hex.decode(hex: hex) else { return nil }
        self = result
    }
    
    func hex(prefix: Bool = true) -> String {
        Hex.encode(data: self, prefix: prefix)
    }
}
