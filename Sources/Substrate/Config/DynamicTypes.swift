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
    
    public var address: TypeDefinition
    public var account: Maybe<TypeDefinition>
    public var block: Maybe<TypeDefinition>
    public var call: TypeDefinition
    public var dispatchError: Maybe<TypeDefinition>
    public var event: TypeDefinition
    public var extrinsicExtra: TypeDefinition
    public var hash: Maybe<TypeDefinition>
    public var hasher: Maybe<AnyFixedHasher.HashType>
    public var signature: TypeDefinition
    public var transactionValidityError: Maybe<TypeDefinition>
    
    public init(address: TypeDefinition, account: Maybe<TypeDefinition>,
                block: Maybe<TypeDefinition>, call: TypeDefinition,
                dispatchError: Maybe<TypeDefinition>, event: TypeDefinition,
                extrinsicExtra: TypeDefinition, hash: Maybe<TypeDefinition>,
                hasher: Maybe<AnyFixedHasher.HashType>, signature: TypeDefinition,
                transactionValidityError: Maybe<TypeDefinition>)
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
        case typeNotFound(name: String, selector: String)
        case subtypeNotFound(name: String, in: String, selector: String)
        case wrongType(name: String, reason: String)
        case unknownHasherType(type: String)
        
        public var debugDescription: String {
            switch self {
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
        let ext: (call: TypeDefinition, address: TypeDefinition, signature: TypeDefinition, extra: TypeDefinition)
        if let addr = metadata.extrinsic.addressType,
           let call = metadata.extrinsic.callType,
           let sig = metadata.extrinsic.signatureType,
           let extra = metadata.extrinsic.extraType
        {
            ext = (call: call, address: addr, signature: sig, extra: extra)
        } else {
            ext = try parseExtrinsicTypes(metadata: metadata).get()
        }
        
        let account: Maybe<TypeDefinition>
        let accountType = ext.address.parameters?.first {
            accountParamNames.contains($0.name.lowercased())
        }?.type
        if let accountType = accountType {
            account = .success(*accountType)
        } else {
            account = metadata.search(type: {accountSelector.matches($0)})
                .map{.success($0)} ?? .failure(.typeNotFound(name: "AccountId",
                                                             selector: accountSelector.pattern))
        }
        
        let block: Maybe<TypeDefinition> = metadata.search(type:{blockSelector.matches($0)})
            .map{.success($0)} ?? .failure(.typeNotFound(name: "Block", selector: blockSelector.pattern))
        
        var event: TypeDefinition
        if let ev = metadata.outerEnums?.eventType {
            event = ev
        } else {
            event = try parseEventType(blockEvents: blockEvents, beKey: blockEventsKey,
                                       metadata: metadata).get()
        }
        
        var header: Maybe<TypeDefinition>! = nil
        if let block = block.value {
            let headerType = try? blockType.headerType(block: block)
            if let headerType = headerType {
                header = .success(headerType)
            }
        }
        if header == nil {
            header = metadata.search(type: { headerSelector.matches($0) })
                .map{.success($0)} ?? .failure(.typeNotFound(name: "Header", selector: headerSelector.pattern))
        }
        
        let hash: Maybe<TypeDefinition> = header!.flatMap { header in
            guard case .composite(fields: let fs) = header.definition else {
                return .failure(.wrongType(name: "Header", reason: "Not a composite"))
            }
            guard let type = fs.first(where:{$0.name?.lowercased().contains("hash") ?? false})?.type else {
                return .failure(.subtypeNotFound(name: "Hash", in: "Header", selector: ".*hash.type"))
            }
            return .success(*type)
        }
        
        let hasher: Maybe<AnyFixedHasher.HashType> = header!.flatMap { header in
            guard let type = header.parameters?.first(where:{$0.name.lowercased() == "hash"})?.type else {
                return .failure(.subtypeNotFound(name: "Hash", in: "Header", selector: "Parameter: Hash"))
            }
            guard let hasherName = type.name.split(separator: ".").last else {
                return .failure(.subtypeNotFound(name: "Hasher", in: "Header", selector: "path"))
            }
            guard let hasher = AnyFixedHasher.HashType(name: String(hasherName)) else {
                return .failure(.unknownHasherType(type: String(hasherName)))
            }
            return .success(hasher)
        }
        
        let dispatchError: Maybe<TypeDefinition> = metadata.search(type: {dispatchErrorSelector.matches($0)})
            .map{.success($0)} ?? .failure(.typeNotFound(name: "DispatchError",
                                                         selector: dispatchErrorSelector.pattern))
        let transError: Maybe<TypeDefinition> = metadata.search(
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
    ) -> Result<(call: TypeDefinition, address: TypeDefinition,
                 signature: TypeDefinition, extra: TypeDefinition), LookupError>
    {
        guard let metaType = metadata.extrinsic.type else {
            return .failure(.subtypeNotFound(name: "NetworkType.Info", in: "Metadata",
                                             selector: ".extrinsic.type"))
        }
        guard let metaTypeParameters = metaType.parameters else {
            return .failure(.wrongType(name: "Extrinsic", reason: "Type parameters is nil"))
        }
        var addressType: TypeDefinition? = nil
        var sigType: TypeDefinition? = nil
        var extraType: TypeDefinition? = nil
        var callType: TypeDefinition? = nil
        for param in metaTypeParameters {
            switch param.name.lowercased() {
            case "address": addressType = *param.type
            case "signature": sigType = *param.type
            case "extra": extraType = *param.type
            case "call": callType = *param.type
            default: continue
            }
        }
        guard let addressType = addressType else
        {
            return .failure(.subtypeNotFound(name: "Address", in: "Extrinsic",
                                             selector: "Parameter: Address"))
        }
        guard let sigType = sigType else {
            return .failure(.subtypeNotFound(name: "Signature", in: "Extrinsic",
                                             selector: "Parameter: Signature"))
        }
        guard let extraType = extraType else {
            return .failure(.subtypeNotFound(name: "Call", in: "Extrinsic",
                                             selector: "Parameter: Call"))
        }
        guard let callType = callType else {
            return .failure(.subtypeNotFound(name: "Extra", in: "Extrinsic",
                                             selector: "Parameter: Extra"))
        }
        return .success((call: callType, address: addressType,
                         signature: sigType, extra: extraType))
    }
    
    // Сan be safely removed after removing metadata v14 (v15 has types inside)
    static func parseEventType<BE: SomeBlockEvents>(
        blockEvents: BE.Type, beKey: (name: String, pallet: String), metadata: any Metadata
    ) -> Result<TypeDefinition, LookupError> {
        guard let beStorage = metadata.resolve(pallet: beKey.pallet)?.storage(name: beKey.name) else {
            return .failure(.subtypeNotFound(name: "Storage", in: "Metadata",
                                             selector: "\(beKey.pallet).\(beKey.name)"))
        }
        guard let type = blockEvents.eventType(events: beStorage.types.value) else {
            return .failure(.subtypeNotFound(name: "Event",
                                             in: String(describing: BE.self),
                                             selector: "Element.Type"))
        }
        return .success(type)
    }
}
