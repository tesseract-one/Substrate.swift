//
//  String+Extensions.swift
//  
//
//  Created by Yehor Popovych on 21/06/2023.
//

import Foundation

public extension String {
    @inlinable
    func camelCased(with separator: Character = "_") -> String {
        return self.lowercased()
            .split(separator: separator)
            .enumerated()
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
            .joined()
    }
}
