//
//  EpochAutorship.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct EpochAutorship: Codable {
    public let primary: Data
    public let secondary: Data
    public let secondaryVrf: Data
}
