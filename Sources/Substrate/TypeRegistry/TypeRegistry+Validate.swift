//
//  TypeRegistry+Validate.swift
//  
//
//  Created by Ostap Danylovych on 26.04.2021.
//

import Foundation
#if !COCOAPODS
import SubstratePrimitives
#endif

extension TypeRegistry {
    func _validate(
        modules: Set<String>?,
        types: Dictionary<DType, ScaleDynamicCodable.Type>,
        metadata: Metadata
    ) throws {
        let missing = metadata.modulesByName.flatMap { (mName, module) -> [(DType, String)] in
            guard modules?.contains(mName) ?? true else { return [] }
            let mPath = mName
            let inEvents = module.eventsByName.values.flatMap { (event) -> [(DType, String)] in
                let ePath = "\(mPath).events['\(event.name)']"
                return event.arguments.enumerated().flatMap { (index, argType) in
                    self._checkType(types: types, type: argType, path: "\(ePath)[\(index)]")
                }
            }
            let inCalls = module.callsByName.values.flatMap { (call) -> [(DType, String)] in
                let cPath = "\(mPath).calls['\(call.name)']"
                return call.types.flatMap { (name, argType) in
                    self._checkType(types: types, type: argType, path: "\(cPath)['\(name)']")
                }
            }
            let inConstants = module.constants.values.flatMap { (const) -> [(DType, String)] in
                self._checkType(
                    types: types, type: const.type, path: "\(mPath).constant['\(const.name)']"
                )
            }
            let inStorage = module.storage.values.flatMap { (item) -> [(DType, String)] in
                self._checkType(
                    types: types, type: item.valueType, path: "\(mPath).storage['\(item.name)\']"
                )
            }
            return inEvents + inCalls + inConstants + inStorage
        }
        if !missing.isEmpty {
            let dictionary = Dictionary(missing.map { ($0.0, [$0.1]) }) { left, right in
                return left + right
            }
            throw TypeRegistryError.validationError(missingTypes: dictionary)
        }
    }
    
    func _checkType(
        types: Dictionary<DType, ScaleDynamicCodable.Type>, type: DType, path: String
    ) -> [(DType, String)] {
        guard types[type] == nil else { return [] }
        switch type {
        case .doNotConstruct(type: let t):
            return _checkType(types: types, type: t, path: "\(path).\(type.description)")
        case .fixed(type: let t, count: _):
            return _checkType(types: types, type: t, path: "\(path).\(type.description)")
        case .optional(element: let t):
            return _checkType(types: types, type: t, path: "\(path).\(type.description)")
        case .compact(type: let t):
            return _checkType(types: types, type: t, path: "\(path).\(type.description)")
        case .collection(element: let t):
            return _checkType(types: types, type: t, path: "\(path).\(type.description)")
        case .result(success: let st, error: let et):
            return _checkType(types: types, type: st, path: "\(path).\(type.description).Success") +
                _checkType(types: types, type: et, path: "\(path).\(type.description).Error")
        case .map(key: let kt, value: let vt):
            return _checkType(types: types, type: kt, path: "\(path).\(type.description).Key") +
                _checkType(types: types, type: vt, path: "\(path).\(type.description).Value")
        case .tuple(elements: let ts):
            return ts.enumerated().flatMap { (index, t) in
                self._checkType(types: types, type: t, path: "\(path).\(type.description).\(index)")
            }
        default:
            return [(type, path)]
        }
    }
}
