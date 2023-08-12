Pod::Spec.new do |s|
  s.name             = 'Substrate'
  s.version          = '999.99.9'
  s.summary          = 'Swift APIs for Polkadot and any Substrate-based chain.'
  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }
  
  s.module_name      = 'Substrate'
  s.swift_version    = '5.7'

  base_platforms     = { :ios => '14.0', :osx => '11.0', :tvos => '14.0' }
  s.platforms        = base_platforms # base_platforms.merge({ :watchos => '7.0' }) # xxHash doesn't support watchOS
  
  s.subspec 'Keychain' do |ss|
    ss.source_files = 'Sources/Keychain/**/*.swift'

    ss.dependency 'Substrate/Substrate'
    ss.dependency 'UncommonCrypto', '~> 0.1.0'
    ss.dependency 'Bip39.swift', '~> 0.1.0'
    ss.dependency 'Sr25519/Sr25519', '~> 0.1.0'
    ss.dependency 'Sr25519/Ed25519', '~> 0.1.0'
    ss.dependency 'CSecp256k1', '~> 0.1.0'
    
    ss.test_spec 'KeychainTests' do |ts|
      ts.platforms = base_platforms
      ts.source_files = 'Tests/KeychainTests/**/*.swift'
    end
  end
  
  s.subspec 'RPC' do |ss|
    ss.source_files = 'Sources/RPC/**/*.swift'

    ss.dependency 'Substrate/Substrate'
    ss.dependency 'JsonRPC.swift', '~> 0.2.0'
    ss.dependency 'Serializable.swift', '~> 0.2.0'
  end
  
  s.subspec 'Substrate' do |ss|
    ss.source_files = 'Sources/Substrate/**/*.swift'
    
    ss.dependency 'Blake2', '~> 0.1.0'
    ss.dependency 'ScaleCodec', '~> 0.3.1'
    ss.dependency 'Tuples', '~> 0.1.0'
    ss.dependency 'ContextCodable.swift', '~> 0.1.0'
    ss.dependency 'xxHash-Swift', '~> 1.1.0'
    ss.dependency 'Serializable.swift', '~> 0.2.0'
    ss.dependency 'Numberick', '~> 0.8.0'
    
    ss.test_spec 'SubstrateTests' do |ts|
      ts.platforms = base_platforms
      ts.source_files = 'Tests/SubstrateTests/**/*.swift'
      ts.resource = 'Tests/SubstrateTests/Resources'
    end
    
    ss.test_spec 'IntegrationTests' do |ts|
      ts.platforms = base_platforms
      ts.source_files = 'Tests/IntegrationTests/**/*.swift'
    end
  end

  s.default_subspecs = 'Substrate', 'RPC'
end
