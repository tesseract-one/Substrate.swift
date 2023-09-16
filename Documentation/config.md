# Config

[Config](../Sources/Substrate/Config/Config.swift) is a crucial object which configures Api for exact Substrate network.

Config is split into two protocols `BasicConfig`, which provides basic types like `Address`, `Account`, `Hasher`, etc.

And a `Config` protocol, which provides managers, error types, etc.

Right now SDK has two implementations: `DynamicConfig`, which can be used with most of the Substrate-based networks, and `SubstrateConfig` which is a static config for `contract-node-template` and compatible networks.

`Config` is a point of SDK extending and should be provided by the user for it's network. Check examples and default implementations to provide your own config.