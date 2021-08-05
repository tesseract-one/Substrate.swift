//
//  CreatedBlock.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct CreatedBlock<H: Hash>: Codable {
    public let hash: H
    public let aux: ImportedAux
}
