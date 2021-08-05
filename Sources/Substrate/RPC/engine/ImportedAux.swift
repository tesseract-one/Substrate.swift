//
//  ImportedAux.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct ImportedAux: Codable {
    public let headerOnly: Bool
    public let clearJustificationRequests: Bool
    public let needsJustification: Bool
    public let badJustification: Bool
    public let needsFinalityProof: Bool
    public let isNewBest: Bool
}
