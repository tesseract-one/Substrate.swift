# Substrate Swift SDK Documentation

There is an example of how to implement and extend static APIs [here](../Examples/Sources/CustomStaticConfig/).

To properly implement static typisation for SDK there is several major parts:

## 1. Core Protocols
First thing that should be known to write proper static types is the [Core Protocols](./protocols.md). This protocols used inside SDK for encoding/decoding, type validation, type conversion, etc.

## 2. Frame Types
Next is a [Frame Types](./frame-types.md), which use this core protocols to implement Frame primitives like Call, Events, Constants, Storage Keys, Runtime Calls.

## 3. Config
[Config](./config.md) is an protocol, which provides config for main Api object. It provides types and needed dynamic configuation, like Address, Account, Hasher types, etc.

## 4. API extensions
And there are [API Extensions](./api-extension.md), which use frame types and special extension points to provide developer-friendly top-level APIs.