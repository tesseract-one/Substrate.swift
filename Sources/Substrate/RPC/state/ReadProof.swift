//
//  ReadProof.swift
//  
//
//  Created by Yehor Popovych on 10.08.2021.
//

import Foundation

public struct ReadProof<H: Hash>: Codable {
    public let at: H
    public let proof: Data
}
