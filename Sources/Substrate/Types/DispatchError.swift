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
    
    public init<C>(value: Value<C>) throws {
        switch value.value {
        case .variant(.map(name: let name, fields: let fields)):
            self.name = name
            self.params = fields
        case .variant(.sequence(name: let name, values: let fields)):
            self.name = name
            self.params = Dictionary(uniqueKeysWithValues: fields.enumerated().map { (String($0.offset), $0.element) })
        }
    }
    
    public init(from decoder: Decoder) throws {
        let value = try SerializableValue(from: decoder)
        switch value {
        case .object(let fields):
            guard fields.keys.count == 1, let name = fields.keys.first else {
                
            }
            self.name = name
            if let value = fields[name]?.object {
                self.params = value
            } else if let value = fields[name]?.array {
                self.params = Dictionary(uniqueKeysWithValues: value.enumerated().map { (String($0.offset), $0.element) })
            } else {
                
            }
        case .string(let name):
            self.name = name
            self.params = [:]
        }
    }
}
