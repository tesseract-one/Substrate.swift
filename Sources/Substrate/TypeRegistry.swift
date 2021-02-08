//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 12/14/20.
//

import Foundation
import SubstratePrimitives
import ScaleCodec

public class TypeRegistry {
    private let metadata: Metadata
    
    private var _events: Dictionary<String, StaticEvent.Type> = [:]
    private var _calls: Dictionary<String, StaticCall.Type> = [:]
    private var _types: Dictionary<DType, ScaleDynamicCodable.Type> = [:]
    private var _reverseTypes: Dictionary<String, DType> = [:]
    
    public init(metadata: Metadata) {
        self.metadata = metadata
    }
    
    public func validate() throws {
        
    }
    
    func decode(static: DType, from decoder: ScaleDecoder) throws -> ScaleDynamicCodable {
        guard let T = _types[`static`] else {
            throw TypeRegistryError.typeNotFound(`static`)
        }
        return try _typeDecodingError(`static`) { try T.init(from: decoder, registry: self) }
    }
}

extension TypeRegistry: TypeRegistryProtocol {
    public func register<T>(type: T.Type, as dynamic: DType) throws where T : ScaleDynamicCodable {
        _types[dynamic] = type
        _reverseTypes[String(describing: type)] = dynamic
    }
    
    public func register<C>(call: C.Type) throws where C : Call {
        _calls["\(C.MODULE).\(C.FUNCTION)"] = call
    }
    
    public func register<E>(event: E.Type) throws where E : Event {
        _events["\(E.MODULE).\(E.EVENT)"] = event
    }
    
    public func type<T>(of t: T.Type) throws -> DType where T : ScaleDynamicCodable {
        guard let type = _reverseTypes[String(describing: t)] else {
            throw TypeRegistryError.unknownType(t)
        }
        return type
    }
    
    public func hash<K: DynamicStorageKey>(of key: K) throws -> Data {
        try _metaError { try self.metadata.hash(of: key, registry: self) }
    }
    
    public func hash<K: StaticStorageKey>(of key: K) throws -> Data  {
         try _metaError { try self.metadata.hash(of: key, registry: self) }
    }
    
    public func hash<K: DynamicStorageKey>(iteratorOf key: K) throws -> Data {
         try _metaError { try self.metadata.hash(iteratorOf: key, registry: self) }
    }
    
    public func hash<K: IterableStaticStorageKey>(iteratorOf key: K) throws -> Data {
        try _metaError { try self.metadata.hash(iteratorOf: key, registry: self) }
    }
    
    public func value<K: DynamicStorageKey>(defaultOf key: K) throws -> DValue {
        try _metaError { try self.metadata.value(defaultOf: key, registry: self) }
    }
    
    public func value<K: StaticStorageKey>(defaultOf key: K) throws -> K.Value {
        try _metaError { try self.metadata.value(defaultOf: key, registry: self) }
    }
    
    public func type<K: AnyStorageKey>(valueOf key: K) throws -> DType {
        try _metaError { try self.metadata.type(valueOf: key) }
    }
    
    public func value<C: DynamicConstant>(of constant: C) throws -> DValue {
        try _metaError { try self.metadata.value(of: constant, registry: self) }
    }
    
    public func value<C: Constant>(of constant: C) throws -> C.Value {
        try _metaError { try self.metadata.value(of: constant, registry: self) }
    }
    
    public func type<C: AnyConstant>(of constant: C) throws -> DType {
        try _metaError { try self.metadata.type(of: constant) }
    }
    
    public func decode<K: DynamicStorageKey>(
        key: K.Type, module: String, field: String, from data: Data
    ) throws -> K {
        let decoder = SCALE.default.decoder(data: data)
        let info = try _decodeStorageItemHeader(module: module, field: field, from: decoder)
        return try _storageKeyDecodingError(module: module, field: field) {
            switch info.type {
            case .plain(_):
                return try key.init(
                    module: module, field: field, types: info.pathTypes,
                    h1: nil, h2: nil, decoder: decoder, registry: self
                )
            case .map(hasher: let h1, key: _, value: _, unused: _):
                return try key.init(
                    module: module, field: field, types: info.pathTypes,
                    h1: h1.hasher, h2: nil, decoder: decoder, registry: self
                )
            case .doubleMap(hasher: let h1, key1: _, key2: _, value: _, key2_hasher: let h2):
                return try key.init(
                    module: module, field: field, types: info.pathTypes,
                    h1: h1.hasher, h2: h2.hasher, decoder: decoder, registry: self
                )
            }
            
        }
    }
    
    public func decode<K: StaticStorageKey>(key: K.Type, from data: Data) throws -> K {
        let decoder = SCALE.default.decoder(data: data)
        let info = try _decodeStorageItemHeader(module: key.MODULE, field: key.FIELD, from: decoder)
        return try _storageKeyDecodingError(module: key.MODULE, field: key.FIELD) {
            switch info.type {
            case .plain(_):
                return try key.init(h1: nil, h2: nil, from: decoder, registry: self)
            case .map(hasher: let hasher, key: _, value: _, unused: _):
                return try key.init(h1: hasher.hasher, h2: nil, from: decoder, registry: self)
            case .doubleMap(hasher: let h1, key1: _, key2: _, value: _, key2_hasher: let h2):
                return try key.init(h1: h1.hasher, h2: h2.hasher, from: decoder, registry: self)
            }
        }
        
    }
    
    public func decode(eventFrom decoder: ScaleDecoder) throws -> AnyEvent {
        let (module, info) = try _decodeEventHeader(from: decoder)
        if let event = _events["\(module).\(info.name)"] {
            return try _eventDecodingError(module: module, event: info.name) {
                try event.init(decodingDataFrom: decoder, registry: self)
            }
        } else {
            let args = try info.arguments.map { try self._decode(type: $0, from: decoder) }
            let data = args.count == 1 ? args.first! : .collection(values: args)
            return DEvent(module: module, event: info.name, data: data)
        }
    }
    
    public func decode<E>(event: E.Type, from decoder: ScaleDecoder) throws -> E where E: Event {
        let (module, info) = try _decodeEventHeader(from: decoder)
        guard event.MODULE == module, event.EVENT == info.name else {
            throw TypeRegistryError.eventFoundWrongEvent(
                module: module, event: info.name, exmodule: event.MODULE, exevent: event.EVENT
            )
        }
        return try _eventDecodingError(module: module, event: info.name) {
            try event.init(decodingDataFrom: decoder, registry: self)
        }
    }
    
    public func value<T: ScaleDynamicCodable>(dynamic val: T) throws -> DValue {
        return .native(type: try type(of: T.self), value: val)
    }
    
    public func encode(value: ScaleDynamicEncodable, type: DType, in encoder: ScaleEncoder) throws {
        try _typeEncodingError(value) { try self._encode(value: value, type: type, in: encoder) }
    }
    
    public func encode(dynamic: DValue, type: DType, in encoder: ScaleEncoder) throws {
        try _encode(dynamic: dynamic, type: type, in: encoder)
    }
    
    public func decode<V>(static: V.Type, as type: DType, from decoder: ScaleDecoder) throws -> V where V : ScaleDynamicDecodable {
        guard _types[type] == `static` else {
            throw TypeRegistryError.typeNotFound(type)
        }
        return try _typeDecodingError(type) { try V(from: decoder, registry: self) }
    }
    
    public func decode(dynamic: DType, from decoder: ScaleDecoder) throws -> DValue {
        return try _typeDecodingError(dynamic) { try self._decode(type: dynamic, from: decoder) }
    }
    
    public func encode(call: AnyCall, in encoder: ScaleEncoder) throws {
        if let call = call as? DynamicCall {
            try _encodeCallHeader(call: call, in: encoder)
            try _encodeDynamicCallParams(call: call, in: encoder)
        } else if let call = call as? StaticCall {
            try _encodeCallHeader(call: call, in: encoder)
            try _callEncodingError(call) { try call.encode(paramsIn: encoder, registry: self) }
        } else {
            throw TypeRegistryError.callEncodingUnknownCallType(call: call)
        }
    }
    
    public func decode(callFrom decoder: ScaleDecoder) throws -> AnyCall {
        let (module, info) = try _decodeCallHeader(from: decoder)
        if let call = _calls["\(module).\(info.name)"] {
            return try _callDecodingError(module: module, funct: info.name) {
                try call.init(decodingParamsFrom: decoder, registry: self)
            }
        } else {
            let args = try info.argumentsList.map { try self._decode(type: $0.1, from: decoder) }
            return DCall(module: module, function: info.name, params: args)
        }
    }
    
    public func decode<C>(call: C.Type, from decoder: ScaleDecoder) throws -> C where C: Call {
        let (module, info) = try _decodeEventHeader(from: decoder)
        guard call.MODULE == module, call.FUNCTION == info.name else {
            throw TypeRegistryError.callFoundWrongCall(
                module: module, function: info.name,
                exmodule: call.MODULE, exfunction: call.FUNCTION
            )
        }
        return try _callDecodingError(module: module, funct: info.name) {
            try call.init(decodingParamsFrom: decoder, registry: self)
        }
    }
}

extension TypeRegistry {
    var meta: Metadata { metadata }
    
    func _eventDecodingError<T>(module: String, event: String, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.eventDecodingError(module: module, event: event, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    func _storageKeyDecodingError<T>(module: String, field: String, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.storageItemDecodingError(module: module, field: field, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    func _callDecodingError<T>(module: String, funct: String, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.callDecodingError(module: module, function: funct, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    @discardableResult
    func _callEncodingError<T>(_ call: AnyCall, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SEncodingError {
            throw TypeRegistryError.callEncodingError(call: call, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    @discardableResult
    func _metaError<T>(_ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as MetadataError {
            throw TypeRegistryError.metadata(error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    @discardableResult
    func _typeDecodingError<T>(_ type: DType, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SDecodingError {
            throw TypeRegistryError.typeDecodingError(type: type, error: e)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
    
    @discardableResult
    func _typeEncodingError<T>(_ value: ScaleDynamicEncodable, _ f: @escaping () throws -> T) throws -> T {
        do {
            return try f()
        } catch let e as TypeRegistryError {
            throw e
        } catch let e as SEncodingError {
            throw TypeRegistryError.encodingError(error: e, value: value)
        } catch {
            throw TypeRegistryError.unknown(error: error)
        }
    }
}
