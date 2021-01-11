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
    private let metadata: Metadata
    
    private var _events: Dictionary<String, Event.Type> = [:]
    private var _calls: Dictionary<String, Call.Type> = [:]
    private var _types: Dictionary<DType, ScaleDynamicDecodable.Type> = [:]
    
    public init(metadata: Metadata) {
        self.metadata = metadata
    }
    
    public func validate() throws {
        
    }
    
    public func key<K>(for key: K) throws -> Data where K : AnyStorageKey {
        fatalError("Not implemented")
    }
    
    public func prefix<K>(for key: K) throws -> Data where K : AnyStorageKey {
        fatalError("Not implemented")
    }
    
    public func decodeEvent(from decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    public func decode(event: String, module: String, from decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    public func register<E>(event: E.Type) throws where E : Event {
        _events["\(E.MODULE).\(E.EVENT)"] = event
    }
    
    public func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws {
        fatalError("Not implemented")
    }
    
    public func decode<V>(static: V.Type, as type: DType, from decoder: ScaleDecoder) throws -> V where V : ScaleDynamicDecodable {
        fatalError("Not implemented")
    }
    
    public func decode(dynamic: DType, from decoder: ScaleDecoder) throws -> DValue {
        fatalError("Not implemented")
    }
    
    public func register<T>(type: T.Type, as dynamic: DType) throws where T : ScaleDynamicDecodable {
        _types[dynamic] = type
    }
    
    public func encode<C>(call: C, in encoder: ScaleEncoder) throws where C : AnyCall {
        fatalError("Not implemented")
    }
    
    public func decodeCall(from decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    
    public func decode(call: String, module: String, from decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    
    public func register<C>(call: C.Type) throws where C : Call {
        _calls["\(C.MODULE).\(C.FUNCTION)"] = call
    }
}
