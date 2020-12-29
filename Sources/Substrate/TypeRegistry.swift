//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import SubstratePrimitives
import ScaleCodec


public class TypeRegistry: SubstratePrimitives.TypeRegistry {
    private var _events: Dictionary<String, Event.Type> = [:]
    private var _calls: Dictionary<String, Call.Type> = [:]
    private var _types: Dictionary<SType, ScaleRegistryDecodable.Type> = [:]
    
    public var metadata: SubstratePrimitives.Metadata! = nil
    
    public func initialize() throws {
        
    }
    
    public func registerEvent<E>(_ t: E.Type) throws where E : Event {
        _events["\(E.MODULE).\(E.EVENT)"] = t
    }
    
    public func registerType<T>(_ t: T.Type, as type: SType) throws where T : ScaleRegistryDecodable {
        _types[type] = t
    }
    
    public func registerCall<C>(_ t: C.Type) throws where C : Call {
        _calls["\(C.MODULE).\(C.FUNCTION)"] = t
    }
    
    public func decodeEvent(from decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    public func encode<V>(value: V, type: SType, in encoder: ScaleEncoder) throws where V : ScaleRegistryEncodable {
        fatalError("Not implemented")
    }
    
    public func decodeValue(type: SType, from decoder: ScaleDecoder) throws -> ScaleRegistryDecodable {
        if let vtype = _types[type] {
            return try vtype.init(from: decoder, with: self)
        } else {
            return try metadata.decode(type: type, from: decoder, with: self)
        }
    }
    
    public func encode<C>(call: C, in encoder: ScaleEncoder) throws where C : AnyCall {
        fatalError("Not implemented")
    }
    
    public func decodeCall(from decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
}
