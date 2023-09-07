//
//  DynamicTypes.swift
//  
//
//  Created by Yehor Popovych on 04/09/2023.
//

import Foundation

// Parsed types from Metadata. Used for validation or dynamic enc/decoding.
public struct DynamicTypes {
    public typealias Maybe<T> = Result<T, LookupError>
    
    public var address: NetworkType.Info
    public var account: Maybe<NetworkType.Info>
    public var block: Maybe<NetworkType.Info>
    public var call: NetworkType.Info
    public var dispatchError: Maybe<NetworkType.Info>
    public var event: NetworkType.Info
    public var extrinsicExtra: NetworkType.Info
    public var hash: Maybe<NetworkType.Info>
    public var hasher: Maybe<AnyFixedHasher.HashType>
    public var signature: NetworkType.Info
    public var transactionValidityError: Maybe<NetworkType.Info>
    
    public init(address: NetworkType.Info, account: Maybe<NetworkType.Info>,
                block: Maybe<NetworkType.Info>, call: NetworkType.Info,
                dispatchError: Maybe<NetworkType.Info>, event: NetworkType.Info,
                extrinsicExtra: NetworkType.Info, hash: Maybe<NetworkType.Info>,
                hasher: Maybe<AnyFixedHasher.HashType>, signature: NetworkType.Info,
                transactionValidityError: Maybe<NetworkType.Info>)
    {
        self.address = address
        self.account = account
        self.block = block
        self.call = call
        self.dispatchError = dispatchError
        self.event = event
        self.extrinsicExtra = extrinsicExtra
        self.hash = hash
        self.hasher = hasher
        self.signature = signature
        self.transactionValidityError = transactionValidityError
    }
}

public extension DynamicTypes {
    enum LookupError: Error, CustomDebugStringConvertible {
        case typeIdNotFound(id: NetworkType.Id)
        case typeNotFound(name: String, selector: String)
        case subtypeNotFound(name: String, in: String, selector: String)
        case wrongType(name: String, reason: String)
        case unknownHasherType(type: String)
        
        public var debugDescription: String {
            switch self {
            case .typeIdNotFound(id: let id):
                return "Type #\(id) not found in metadata"
            case .typeNotFound(name: let n, selector: let s):
                return "Type \(n) not found in medatadat by \"\(s)\" selector"
            case .subtypeNotFound(name: let n, in: let i, selector: let s):
                return "Type \(n) not found in the type \(i) metadata using \"\(s)\" selector"
            case .wrongType(name: let n, reason: let r):
                return "Bad type \(n), reason: \(r)"
            case .unknownHasherType(type: let t):
                return "Unknown hasher with type: \(t)"
            
            }
        }
    }
}

public extension DynamicTypes {
    // Default implementation. Should work on most networks. Provide own if needed
    static func tryParse<BE, BC>(
        from metadata: any Metadata, block blockType: BC.Type,
        blockEvents: BE.Type, blockEventsKey: (name: String, pallet: String),
        accountParamNames: [String] = ["accountid", "t::accountid", "account", "acc", "a"],
        accountSelector: NSRegularExpression = try! NSRegularExpression(pattern: "^.*AccountId[0-9]*$"),
        blockSelector: NSRegularExpression = try! NSRegularExpression(pattern: "^.*Block$"),
        headerSelector: NSRegularExpression = try! NSRegularExpression(pattern: "^.*Header$"),
        dispatchErrorSelector: NSRegularExpression = try! NSRegularExpression(pattern: "^.*DispatchError$"),
        transactionValidityErrorSelector: NSRegularExpression =
            try! NSRegularExpression(pattern: "^.*TransactionValidityError$")
    ) throws -> Self where BE: SomeBlockEvents, BC: SomeBlock {
        // Extsinsic info
        let ext: (call: NetworkType.Info, address: NetworkType.Info,
                  signature: NetworkType.Info, extra: NetworkType.Info)
        if let addr = metadata.extrinsic.addressType,
           let call = metadata.extrinsic.callType,
           let sig = metadata.extrinsic.signatureType,
           let extra = metadata.extrinsic.extraType
        {
            ext = (call: call, address: addr, signature: sig, extra: extra)
        } else {
            ext = try parseExtrinsicTypes(metadata: metadata).get()
        }
        
        let account: Maybe<NetworkType.Info>
        let accountId = ext.address.type.parameters.first {
            accountParamNames.contains($0.name.lowercased())
        }?.type
        if let id = accountId, let type = metadata.resolve(type: id) {
            account = .success(id.i(type))
        } else {
            account = metadata.search(type: {accountSelector.matches($0)})
                .map{.success($0)} ?? .failure(.typeNotFound(name: "AccountId",
                                                             selector: accountSelector.pattern))
        }
        
        let block: Maybe<NetworkType.Info> = metadata.search(type:{blockSelector.matches($0)})
            .map{.success($0)} ?? .failure(.typeNotFound(name: "Block", selector: blockSelector.pattern))
        
        var event: NetworkType.Info
        if let ev = metadata.outerEnums?.eventType {
            event = ev
        } else {
            event = try parseEventType(blockEvents: blockEvents, beKey: blockEventsKey,
                                       metadata: metadata).get()
        }
        
        var header: Maybe<NetworkType.Info>! = nil
        if let block = block.value {
            let headerId = try? blockType.headerType(metadata: metadata, block: block.type)
            if let id = headerId, let type = metadata.resolve(type: id) {
                header = .success(id.i(type))
            }
        }
        if header == nil {
            header = metadata.search(type: { headerSelector.matches($0) })
                .map{.success($0)} ?? .failure(.typeNotFound(name: "Header", selector: headerSelector.pattern))
        }
        
        let hash: Maybe<NetworkType.Info> = header!.flatMap { header in
            guard case .composite(fields: let fs) = header.type.definition else {
                return .failure(.wrongType(name: "Header", reason: "Not a composite"))
            }
            guard let id = fs.first(where:{$0.typeName?.lowercased().contains("hash") ?? false})?.type else {
                return .failure(.subtypeNotFound(name: "Hash", in: "Header", selector: ".hash.typeName"))
            }
            guard let type = metadata.resolve(type: id) else {
                return .failure(.typeIdNotFound(id: id))
            }
            return .success(id.i(type))
        }
        
        let hasher: Maybe<AnyFixedHasher.HashType> = header!.flatMap { header in
            guard let id = header.type.parameters.first(where:{$0.name.lowercased() == "hash"})?.type else {
                return .failure(.subtypeNotFound(name: "Hash", in: "Header", selector: "Parameter: Hash"))
            }
            guard let type = metadata.resolve(type: id) else {
                return .failure(.typeIdNotFound(id: id))
            }
            guard let hasherName = type.path.last else {
                return .failure(.subtypeNotFound(name: "Hasher", in: "Header", selector: "path"))
            }
            guard let hasher = AnyFixedHasher.HashType(name: hasherName) else {
                return .failure(.unknownHasherType(type: hasherName))
            }
            return .success(hasher)
        }
        
        let dispatchError: Maybe<NetworkType.Info> = metadata.search(type: {dispatchErrorSelector.matches($0)})
            .map{.success($0)} ?? .failure(.typeNotFound(name: "DispatchError",
                                                         selector: dispatchErrorSelector.pattern))
        let transError: Maybe<NetworkType.Info> = metadata.search(
            type: {transactionValidityErrorSelector.matches($0)}
        ).map{.success($0)} ?? .failure(.typeNotFound(name: "TransactionValidityError",
                                                      selector: dispatchErrorSelector.pattern))
        
        return DynamicTypes(address: ext.address, account: account, block: block,
                                  call: ext.call, dispatchError: dispatchError, event: event,
                                  extrinsicExtra: ext.extra, hash: hash, hasher: hasher,
                                  signature: ext.signature, transactionValidityError: transError)
    }
    
    // Сan be safely removed after removing metadata v14 (v15 has types inside)
    static func parseExtrinsicTypes(
        metadata: any Metadata
    ) -> Result<(call: NetworkType.Info, address: NetworkType.Info,
                 signature: NetworkType.Info, extra: NetworkType.Info), LookupError>
    {
        guard let metaType = metadata.extrinsic.type else {
            return .failure(.subtypeNotFound(name: "NetworkType.Info", in: "Metadata",
                                             selector: ".extrinsic.type"))
        }
        var addressId: NetworkType.Id? = nil
        var sigId: NetworkType.Id? = nil
        var extraId: NetworkType.Id? = nil
        var callId: NetworkType.Id? = nil
        for param in metaType.type.parameters {
            switch param.name.lowercased() {
            case "address": addressId = param.type
            case "signature": sigId = param.type
            case "extra": extraId = param.type
            case "call": callId = param.type
            default: continue
            }
        }
        guard let addressId = addressId, let addressType = metadata.resolve(type: addressId) else
        {
            return .failure(.subtypeNotFound(name: "Address", in: "Extrinsic",
                                             selector: "Parameter: Address"))
        }
        guard let sigId = sigId, let sigType = metadata.resolve(type: sigId) else {
            return .failure(.subtypeNotFound(name: "Signature", in: "Extrinsic",
                                             selector: "Parameter: Signature"))
        }
        guard let callId = callId, let callType = metadata.resolve(type: callId) else {
            return .failure(.subtypeNotFound(name: "Call", in: "Extrinsic",
                                             selector: "Parameter: Call"))
        }
        guard let extraId = extraId, let extraType = metadata.resolve(type: extraId) else {
            return .failure(.subtypeNotFound(name: "Extra", in: "Extrinsic",
                                             selector: "Parameter: Extra"))
        }
        return .success((call: callId.i(callType), address: addressId.i(addressType),
                         signature: sigId.i(sigType), extra: extraId.i(extraType)))
    }
    
    // Сan be safely removed after removing metadata v14 (v15 has types inside)
    static func parseEventType<BE: SomeBlockEvents>(
        blockEvents: BE.Type, beKey: (name: String, pallet: String), metadata: any Metadata
    ) -> Result<NetworkType.Info, LookupError> {
        guard let beStorage = metadata.resolve(pallet: beKey.pallet)?.storage(name: beKey.name) else {
            return .failure(.subtypeNotFound(name: "Storage", in: "Metadata",
                                             selector: "\(beKey.pallet).\(beKey.name)"))
        }
        guard let id = blockEvents.eventTypeId(metadata: metadata,
                                               events: beStorage.types.value) else {
            return .failure(.subtypeNotFound(name: "Event",
                                             in: String(describing: BE.self),
                                             selector: "Element.Type"))
        }
        guard let type = metadata.resolve(type: id) else {
            return .failure(.typeIdNotFound(id: id))
        }
        return .success(id.i(type))
    }
}
