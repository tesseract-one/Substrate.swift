//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import SubstratePrimitives
import ScaleCodec

public class TypeRegistry: TypeRegistryProtocol {
    private var _events: Dictionary<String, Event.Type> = [:]
    private var _calls: Dictionary<String, Call.Type> = [:]
    private var _types: Dictionary<DType, ScaleDynamicDecodable.Type> = [:]
    
    public func check(meta: MetadataProtocol) throws {
        
    }
    
    public func registerEvent<E>(_ t: E.Type) throws where E : Event {
        _events["\(E.MODULE).\(E.EVENT)"] = t
    }
    
    public func registerType<T>(_ t: T.Type, as type: DType) throws where T : ScaleDynamicDecodable {
        _types[type] = t
    }
    
    public func registerCall<C>(_ t: C.Type) throws where C : Call {
        _calls["\(C.MODULE).\(C.FUNCTION)"] = t
    }
    
    public func hasEventType<E>(_ t: E.Type) -> Bool where E : Event {
        return false
    }
       
    public func hasValueType<T>(_ t: T.Type, for type: DType) -> Bool where T : ScaleDynamicDecodable {
        return false
    }
       
    public func hasCallType<C>(_ t: C.Type) -> Bool where C : Call {
        return false
    }
    
    public func decodeEvent(event: String, module: String, from decoder: ScaleDecoder, with meta: MetadataProtocol) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    public func encode<V>(value: V, type: DType, in encoder: ScaleEncoder, with meta: MetadataProtocol) throws where V : ScaleDynamicEncodable {
        fatalError("Not implemented")
    }
    
    public func decodeValue(type: DType, from decoder: ScaleDecoder, with meta: MetadataProtocol) throws -> ScaleDynamicDecodable {
        guard let vtype = _types[type] else {
            throw TypeRegistryError.typeNotFound(type)
        }
        return try vtype.init(from: decoder, meta: meta)
    }
    
    public func encode<C>(call: C, in encoder: ScaleEncoder, with meta: MetadataProtocol) throws where C : AnyCall {
        fatalError("Not implemented")
    }
    
    public func decodeCall(event: String, module: String, from decoder: ScaleDecoder, with meta: MetadataProtocol) throws -> AnyCall {
        fatalError("Not implemented")
    }
}
