//
//  ChainType.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public enum ChainType: Equatable, Decodable {
    case development
    case local
    case live
    case custom(String)
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            switch simple {
            case "Development": self = .development
            case "Local": self = .local
            case "Live": self = .live
            default:
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            guard key == .custom else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
            self = try .custom(container2.decode(String.self, forKey: key))
        }
    }
}

private extension CodableComplexKey where T == ChainType {
    static let custom = Self(stringValue: "Custom")!
}
