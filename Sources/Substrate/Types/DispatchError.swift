//
//  DispatchError.swift
//  
//
//  Created by Yehor Popovych on 05/06/2023.
//

import Foundation
import Serializable

public protocol SomeDispatchError: Error, ValueInitializable, Decodable {
    var name: String { get }
    var params: [String: Any] { get }
}


public struct AnyDispatchError: SomeDispatchError {
    public let name: String
    public let params: [String : Any]
    
    public enum Error: Swift.Error {
        case valueIsNotVariant(Value<Void>)
        case valueIsNotObject(SerializableValue)
        case moreThanOneKey(SerializableValue)
    }
    
    public init<C>(value: Value<C>) throws {
        switch value.value {
        case .variant(.map(name: let name, fields: let fields)):
            self.name = name
            self.params = fields
        case .variant(.sequence(name: let name, values: let fields)):
            self.name = name
            self.params = Dictionary(uniqueKeysWithValues: fields.enumerated().map { (String($0.offset), $0.element) })
        default: throw Error.valueIsNotVariant(value.mapContext{_ in})
        }
    }
    
    public init(from decoder: Decoder) throws {
        let value = try SerializableValue(from: decoder)
        switch value {
        case .object(let fields):
            guard fields.keys.count == 1, let name = fields.keys.first else {
                throw Error.moreThanOneKey(value)
            }
            self.name = name
            if let value = fields[name]?.object {
                self.params = value
            } else if let value = fields[name]?.array {
                self.params = Dictionary(uniqueKeysWithValues: value.enumerated().map { (String($0.offset), $0.element) })
            } else {
                throw Error.valueIsNotObject(fields[name]!)
            }
        case .string(let name):
            self.name = name
            self.params = [:]
        default: throw Error.valueIsNotObject(value)
        }
    }
}
