//
//  TypeRegistry+Validate.swift
//  
//
//  Created by Ostap Danylovych on 26.04.2021.
//

import Foundation
import SubstratePrimitives

extension TypeRegistry {
    func _checkType(types: Dictionary<DType, ScaleDynamicCodable.Type>, type: DType) -> Set<DType> {
        var missing = Set<DType>()
        let check = { (type: DType) in
            missing = missing.union(self._checkType(types: types, type: type))
        }
        if types[type] == nil {
            switch type {
            case .doNotConstruct(let type): check(type)
            case .compact(let type): check(type)
            case .collection(let element): check(element)
            case .fixed(let type, _): check(type)
            case .optional(let element): check(element)
            case .map(let key, let value):
                check(key)
                check(value)
            case .result(let success, let error):
                check(success)
                check(error)
            case .tuple(let elements):
                for element in elements {
                    check(element)
                }
            default:
                missing.insert(type)
            }
        }
        return missing
    }
}
