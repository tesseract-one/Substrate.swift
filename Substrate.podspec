Pod::Spec.new do |s|
  s.name             = 'Substrate'
  s.version          = '0.0.1'
  s.summary          = 'Swift APIs for Polkadot and any Substrate-based chain.'

  s.homepage         = 'https://github.com/tesseract-one/Substrate.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Substrate.swift.git', :tag => s.version.to_s }

  test_platforms = {
    :ios => '10.0',
    :osx => '10.12',
    :tvos => '10.0'
  }

  s.platforms = test_platforms.merge({ :watchos => '6.0' })
  
  s.swift_versions = ['5', '5.1', '5.2', '5.3']
  
  s.module_name = 'Substrate'
  
  s.subspec 'Keychain' do |ss|
    ss.source_files = 'Sources/Keychain/**/*.swift'

    ss.dependency 'Substrate/Substrate'
    ss.dependency 'UncommonCrypto', '~> 0.1'
    ss.dependency 'Bip39.swift', '~> 0.1'
    ss.dependency 'Sr25519', '~> 0.1'
    ss.dependency 'CSecp256k1', '~> 0.1'
    
    ss.test_spec 'KeychainTests' do |test_spec|
      test_spec.platforms = test_platforms
      test_spec.source_files = 'Tests/KeychainTests/**/*.swift'
    end
  end
  
  s.subspec 'Substrate' do |ss|
    ss.source_files = 'Sources/Substrate/**/*.swift'

    ss.dependency 'Substrate/Primitives'
    ss.dependency 'Substrate/RPC'
    
    ss.test_spec 'SubstrateTests' do |test_spec|
      test_spec.platforms = test_platforms
      test_spec.source_files = 'Tests/SubstrateTests/**/*.swift'
    end
  end

  s.subspec 'Polkadot' do |ss|
    ss.source_files = 'Sources/Polkadot/**/*.swift'

    ss.dependency 'Substrate/Substrate'
    
    ss.test_spec 'PolkadotTests' do |test_spec|
      test_spec.platforms = test_platforms
      test_spec.source_files = 'Tests/PolkadotTests/**/*.swift'
    end
  end

  s.subspec 'Primitives' do |ss|
    ss.source_files = 'Sources/Primitives/**/*.swift'

    ss.dependency 'Blake2', '~> 0.1'
    ss.dependency 'ScaleCodec', '~> 0.2'
    ss.dependency 'xxHash-Swift', '~> 1.1'
    
    ss.test_spec 'PrimitivesTests' do |test_spec|
      test_spec.platforms = test_platforms
      test_spec.source_files = 'Tests/PrimitivesTests/**/*.swift'
    end
  end
  
  s.subspec 'RPC' do |ss|
    ss.source_files = 'Sources/RPC/**/*.swift'

    ss.dependency 'TesseractWebSocket', '~> 0.0.1'
    
    ss.test_spec 'RPCTests' do |test_spec|
      test_spec.platforms = test_platforms
      test_spec.dependency 'Serializable.swift', '~> 0.2'
      test_spec.source_files = 'Tests/RPCTests/**/*.swift'
    end
  end

  s.default_subspecs = 'Substrate'
end
